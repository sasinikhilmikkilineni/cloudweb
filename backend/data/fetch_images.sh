#!/usr/bin/env bash
set -euo pipefail

# Set your bucket (pull from Terraform output if you want)
BUCKET="${BUCKET:-$(terraform -chdir=../infra output -raw frontend_bucket_name 2>/dev/null || echo '')}"
if [[ -z "${BUCKET}" ]]; then
  echo "Set BUCKET env var or run from a dir where 'terraform -chdir=../infra output' works."
  exit 1
fi

mkdir -p /tmp/proshop-images && cd /tmp/proshop-images

# filename -> search keywords
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
  [nighthawk-ax5400.jpg]="netgear nighthawk router"
  [samsung-uhd27.jpg]="samsung 27 inch 4k monitor"
  [asus-tuf-27.jpg]="asus tuf gaming monitor"
  [seagate-2tb.jpg]="seagate external hard drive"
  [sandisk-extreme-1tb.jpg]="sandisk extreme portable ssd"
)

for file in "${!IMG_MAP[@]}"; do
  q="${IMG_MAP[$file]}"
  # download a representative 800x800 image for the given keywords
  curl -fsSL -o "$file" "https://source.unsplash.com/800x800/?$(sed 's/ /%20/g' <<<"$q")"
  # upload to your S3 bucket under /images
  aws s3 cp "$file" "s3://${BUCKET}/images/${file}"
done

echo "Uploaded images to s3://${BUCKET}/images/"
