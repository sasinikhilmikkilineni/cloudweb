#!/usr/bin/env bash
set -euo pipefail

# --- deps ---
for dep in aws terraform curl; do
  command -v "$dep" >/dev/null 2>&1 || { echo "Missing $dep"; exit 1; }
done

# --- config from Terraform (overridable via env) ---
BUCKET="${BUCKET:-$(terraform output -raw frontend_bucket_name 2>/dev/null || true)}"
CF_DOMAIN="${CF_DOMAIN:-$(terraform output -raw cloudfront_domain 2>/dev/null || true)}"

if [[ -z "${BUCKET}" || -z "${CF_DOMAIN}" ]]; then
  echo "Could not read outputs. Ensure you're in ~/Cloudproject/infra and have applied Terraform."
  echo "Alternatively: export BUCKET=<your-bucket> and CF_DOMAIN=<your-cf-domain> and rerun."
  exit 1
fi

AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_REGION
export AWS_DEFAULT_REGION="$AWS_REGION"

echo "Account: $(aws sts get-caller-identity --query Account --output text)"
echo "Bucket : $BUCKET"
echo "CF     : $CF_DOMAIN"
echo

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"

# --- filenames -> keywords (20 images) ---
declare -A IMG_MAP=(
  [qc45.jpg]="bose quietcomfort headphones"
  [wh1000xm5.jpg]="sony wh-1000xm5 headphones"
  [pixel-buds-pro.jpg]="google pixel buds pro earbuds"
  [galaxy-s23.jpg]="samsung galaxy s23 smartphone"
  [pixel7.jpg]="google pixel 7 smartphone"
  [ipad-air-5.jpg]="ipad air 5th generation tablet"
  [canon-r50.jpg]="canon r50 mirrorless camera"
  [nikon-z50.jpg]="nikon z50 mirrorless camera"
  [dji-mini-3.jpg]="dji mini 3 drone"
  [jbl-flip6.jpg]="jbl flip 6 bluetooth speaker"
  [blackwidow-v3.jpg]="razer blackwidow mechanical keyboard"
  [logitech-c920.jpg]="logitech c920 webcam"
  [dell-xps-13.jpg]="dell xps 13 laptop"
  [apple-watch-se2.jpg]="apple watch se 2"
  [fitbit-versa-4.jpg]="fitbit versa 4"
  [archer-ax55.jpg]="tp-link archer ax55 router"
  [nighthawk-ax5400.jpg]="netgear nighthawk ax5400 router"
  [samsung-uhd27.jpg]="samsung 27 inch 4k monitor"
  [asus-tuf-27.jpg]="asus tuf gaming 27 monitor"
  [sandisk-extreme-1tb.jpg]="sandisk extreme portable ssd"
)

echo "Downloading 20 images..."
for f in "${!IMG_MAP[@]}"; do
  q="${IMG_MAP[$f]}"
  url="https://source.unsplash.com/seed/${f}/800x800/?$(printf '%s' "$q" | sed 's/ /%20/g')"
  printf "  - %-26s ← %s\n" "$f" "$q"
  curl -fsSL --retry 3 -o "$f" "$url"
  [[ -s "$f" ]] || { echo "Download failed for $f"; exit 1; }
done

echo
echo "Uploading to s3://$BUCKET/images/ ..."
aws s3 sync . "s3://${BUCKET}/images/" --exact-timestamps \
  --exclude ".DS_Store" \
  --cache-control "public,max-age=31536000,immutable"

echo
echo "Invalidating CloudFront ..."
dist_id="$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?DomainName=='$CF_DOMAIN'].Id | [0]" --output text)"

if [[ -z "$dist_id" || "$dist_id" == "None" || "$dist_id" == "null" ]]; then
  echo "Could not resolve distribution ID for $CF_DOMAIN"; exit 1
fi

aws cloudfront create-invalidation --distribution-id "$dist_id" --paths "/*" >/dev/null

echo
echo "Done. Sample URLs:"
for f in "${!IMG_MAP[@]}"; do
  echo "  https://$CF_DOMAIN/images/$f"
done
