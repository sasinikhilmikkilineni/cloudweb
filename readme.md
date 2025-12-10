# ProShop eCommerce Platform (v2) - CloudWeb Edition

> eCommerce platform built with the MERN stack & Redux.

This project is based on the [MERN Stack From Scratch | eCommerce Platform](https://www.traversymedia.com/mern-stack-from-scratch) course. It is a full-featured shopping cart with PayPal & credit/debit payments.

This is version 2.0 of the app, which uses Redux Toolkit. The original course version can be found [here](https://proshopdemo.dev)

**CloudWeb Edition:** This version has been enhanced with production-grade AWS infrastructure including ECS Fargate, ALB, RDS, MongoDB Atlas integration, and automated deployment pipelines.

<!-- toc -->

- [Features](#features)
- [Usage](#usage)
  - [Env Variables](#env-variables)
  - [Install Dependencies (frontend & backend)](#install-dependencies-frontend--backend)
  - [Run](#run)
- [Build & Deploy](#build--deploy)
  - [Seed Database](#seed-database)
  - [AWS Deployment](#aws-deployment)
- [CloudWeb Infrastructure](#cloudweb-infrastructure)
- [Bug Fixes, corrections and code FAQ](#bug-fixes-corrections-and-code-faq)
  - [BUG: Warnings on ProfileScreen](#bug-warnings-on-profilescreen)
  - [BUG: Changing an uncontrolled input to be controlled](#bug-changing-an-uncontrolled-input-to-be-controlled)
  - [BUG: All file types are allowed when updating product images](#bug-all-file-types-are-allowed-when-updating-product-images)
  - [BUG: Throwing error from productControllers will not give a custom error response](#bug-throwing-error-from-productcontrollers-will-not-give-a-custom-error-response)
  - [BUG: Bad responses not handled in the frontend](#bug-bad-responses-not-handled-in-the-frontend)
  - [BUG: After switching users, our new user gets the previous users cart](#bug-after-switching-users-our-new-user-gets-the-previous-users-cart)
  - [BUG: Passing a string value to our `addDecimals` function](#bug-passing-a-string-value-to-our-adddecimals-function)
  - [BUG: Token and Cookie expiration not handled in frontend](#bug-token-and-cookie-expiration-not-handled-in-frontend)
  - [BUG: Calculation of prices as decimals gives odd results](#bug-calculation-of-prices-as-decimals-gives-odd-results)
  - [FAQ: How do I use Vite instead of CRA?](#faq-how-do-i-use-vite-instead-of-cra)
  - [FIX: issues with LinkContainer](#fix-issues-with-linkcontainer)
- [License](#license)

<!-- tocstop -->

## Features

- Full featured shopping cart
- Product reviews and ratings
- Top products carousel
- Product pagination
- Product search feature
- User profile with orders
- Admin product management
- Admin user management
- Admin Order details page
- Mark orders as delivered option
- Checkout process (shipping, payment method, etc)
- PayPal / credit card integration
- Database seeder (products & users)
- **AWS ECS Fargate deployment with ALB**
- **MongoDB Atlas integration**
- **VPC with public/private subnets**
- **Secrets Manager integration**
- **CloudWatch logging**
- **AWS Config compliance monitoring**

## Usage

- Create a MongoDB database and obtain your `MongoDB URI` - [MongoDB Atlas](https://www.mongodb.com/cloud/atlas/register)
- Create a PayPal account and obtain your `Client ID` - [PayPal Developer](https://developer.paypal.com/)

### Env Variables

Rename the `.env.example` file to `.env` and add the following

```
NODE_ENV = development
PORT = 5000
MONGO_URI = your mongodb uri
JWT_SECRET = 'abc123'
PAYPAL_CLIENT_ID = your paypal client id
PAGINATION_LIMIT = 8
```

Change the JWT_SECRET and PAGINATION_LIMIT to what you want

### Install Dependencies (frontend & backend)

```
npm install
cd frontend
npm install
```

### Run

```
# Run frontend (:3000) & backend (:5000)
npm run dev

# Run backend only
npm run server

# Run frontend only (from frontend directory)
npm run dev
```

## Build & Deploy

### Local Docker Deployment

```
# Build and run with Docker Compose
docker-compose up --build

# Containers will start:
# - Frontend: http://localhost:3000
# - Backend: http://localhost:5000
# - Mock API: http://localhost:3001
```

### Seed Database

You can use the following commands to seed the database with some sample users and products as well as destroy all data

```
# Import data
npm run data:import

# Destroy data
npm run data:destroy
```

```
Sample User Logins

admin@email.com (Admin)
123456

john@email.com (Customer)
123456

jane@email.com (Customer)
123456
```

### AWS Deployment

This project includes production-grade AWS infrastructure defined with Terraform.

#### Prerequisites

- AWS Account (account ID: 085953615294)
- AWS CLI configured with appropriate credentials
- Terraform installed (>= 1.0)
- Docker & Docker Compose

#### AWS Resources Deployed

- **VPC**: Custom VPC with 4 subnets (2 public, 2 private) across 2 AZs
- **Application Load Balancer**: Routes traffic to frontend and backend
- **ECS Fargate**: Containerized services for frontend and backend
- **RDS**: Relational database support (configured via variables)
- **Secrets Manager**: Secure storage for MongoDB URI, JWT Secret, PayPal Client ID
- **ECR**: Private container registries for frontend and backend images
- **CloudWatch**: Centralized logging for all services
- **AWS Config**: Compliance monitoring and tagging enforcement
- **NAT Gateways**: Outbound internet access from private subnets

#### Deployment Steps

1. **Setup Terraform Variables**
   ```
   cd infra
   # Edit terraform.tfvars with your AWS account details
   vim terraform.tfvars
   ```

2. **Create AWS Secrets** (if not already created)
   ```
   # MongoDB URI
   aws secretsmanager create-secret \
     --name proshop/MONGO_URI \
     --secret-string "mongodb+srv://..." \
     --region us-west-2

   # JWT Secret
   aws secretsmanager create-secret \
     --name proshop/JWT_SECRET \
     --secret-string "your-jwt-secret" \
     --region us-west-2

   # PayPal Client ID
   aws secretsmanager create-secret \
     --name proshop/PAYPAL_CLIENT_ID \
     --secret-string "your-paypal-client-id" \
     --region us-west-2
   ```

3. **Build and Push Docker Images to ECR**
   ```
   # Authenticate with ECR
   aws ecr get-login-password --region us-west-2 | \
     docker login --username AWS --password-stdin 085953615294.dkr.ecr.us-west-2.amazonaws.com

   # Build and push backend
   cd ../backend
   docker build -t proshop-backend:latest .
   docker tag proshop-backend:latest \
     085953615294.dkr.ecr.us-west-2.amazonaws.com/proshop-backend:latest
   docker push 085953615294.dkr.ecr.us-west-2.amazonaws.com/proshop-backend:latest

   # Build and push frontend
   cd ../frontend
   docker build -t proshop-frontend:latest .
   docker tag proshop-frontend:latest \
     085953615294.dkr.ecr.us-west-2.amazonaws.com/proshop-frontend:latest
   docker push 085953615294.dkr.ecr.us-west-2.amazonaws.com/proshop-frontend:latest
   ```

4. **Deploy Infrastructure with Terraform**
   ```
   cd ../infra
   terraform init
   terraform plan
   terraform apply
   ```

5. **Access the Application**
   ```
   # Get the ALB DNS name
   aws elbv2 describe-load-balancers \
     --names proshop-alb \
     --region us-west-2 \
     --query 'LoadBalancers[0].DNSName' \
     --output text
   ```

#### Infrastructure Highlights

- **Highly Available**: Deployed across 2 Availability Zones
- **Auto-Scaling**: ECS services configured for auto-scaling based on CPU/Memory
- **Secure**: Secrets Manager for sensitive data, Security Groups for network isolation, VPC Endpoints for private access to AWS services
- **Observable**: CloudWatch logs for all services, AWS Config for compliance
- **Scalable**: Load Balanced architecture, containerized workloads

#### Architecture Diagram

```
Internet → ALB (public subnet) → ECS Services (private subnets) → RDS / MongoDB Atlas
                                        ↓
                              Secrets Manager (VPC Endpoint)
                              CloudWatch Logs
                              AWS Config
```

---

# Bug Fixes, corrections and code FAQ

The code here in the main branch has been updated since the course was published to fix bugs found by students of the course and answer common questions, if you are looking to compare your code to that from the course lessons then
please refer to the [originalcoursecode](https://github.com/bradtraversy/proshop-v2/tree/originalCourseCode) branch of this repository.

There are detailed notes in the comments that will hopefully help you understand
and adopt the changes and corrections.
An easy way of seeing all the changes and fixes is to use a note highlighter
extension such as [This one for VSCode](https://marketplace.visualstudio.com/items?itemName=wayou.vscode-todo-highlight) or [this one for Vim](https://github.com/folke/todo-comments.nvim) Where by you can easily list all the **NOTE:** and **FIX:** tags in the comments.

### BUG: Warnings on ProfileScreen

When we use `<Form.Control/>` element and set a value on it like so:

```jsx
<Form.Control as='input' value={email} />
```

We will get the following warning:

```
You provided a `value` prop to a form field without an `onChange` handler. This will render a read-only field. If the field should be mutable use `defaultValue`. Otherwise, set either `onChange` or `readOnly`.
```

To fix we need to add an `onChange` to the input

```jsx
<Form.Control
  type='email'
  placeholder='Email address'
  value={email}
  onChange={(e) => setEmail(e.target.value)}
></Form.Control>
```

> Changes can be seen in [ProfileScreen.jsx](frontend/src/screens/ProfileScreen.jsx)

---

### BUG: Changing an uncontrolled input to be controlled

When you use a uncontrolled input component and then add a value property to it, React will output the following error:

```
A component is changing an uncontrolled input to be controlled
```

This means you cannot add a value property unless you also add an onChange handler.

To ensure that doesn't happen when user logs out after updating their profile, we use the `useEffect` hook to reset the form:

```jsx
useEffect(() => {
  setName(userInfo.name);
  setEmail(userInfo.email);
}, [userInfo]);
```

> Changes can be seen in [ProfileScreen.jsx](frontend/src/screens/ProfileScreen.jsx)

---

### BUG: All file types are allowed when updating product images

When updating and uploading product images as an Admin user, all file types are allowed. We only want to upload image files. This is fixed by using a fileFilter function and sending back an appropriate error when the wrong file type is uploaded.

You may see that our `checkFileType` function is declared but never actually
used, this change fixes that. The function has been renamed to `fileFilter` and
passed to the instance of [ multer ](https://github.com/expressjs/multer#filefilter)

> Code changes can be seen in [uploadRoutes.js](backend/routes/uploadRoutes.js)

---

### BUG: Throwing error from productControllers will not give a custom error response

#### Original code

```js
if (!product) {
  throw new Error('Product not found');
}
```

The issue is that throwing a regular error will not pass through our error middleware (errorMiddleware.js) correctly. We need to use the `asyncHandler` to catch it.

The asyncHandler is already being used as middleware on the route, so it will catch any errors thrown in the controller.

```js
if (!product) {
  throw new Error('Product not found');
}
```

But the error middleware expects an error that is an instance of Error or has a custom status code. The solution is to use the custom error class:

```js
import { v4 as uuidv4 } from 'uuid';

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
  }
}
```

Then throw it like so:

```js
if (!product) {
  throw new AppError('Product not found', 404);
}
```

However, looking at the code, the `asyncHandler` will catch it and pass it to the error middleware, and the error middleware will return a 500 status code if the error doesn't have a statusCode.

The solution is to use the `checkObjectId` middleware on the routes that use the product id to validate the id before it gets to the controller. This way if an invalid id is passed, a proper error response will be sent before the controller is even called.

> Changes can be seen in [errorMiddleware.js](backend/middleware/errorMiddleware.js), [productRoutes.js](backend/routes/productRoutes.js), [productController.js](backend/controllers/productController.js) and [checkObjectId.js](backend/middleware/checkObjectId.js)

---

### BUG: Bad responses not handled in the frontend

There are a few cases in our frontend where if we get a bad response from our
API then we try and render the error object.
This you cannot do in React - if you are seeing an error along the lines of
**Objects are not valid as a React child** and the app breaks for you, then this
is likely the fix you need.

#### Example from PlaceOrderScreen.jsx

```jsx
<ListGroup.Item>
  {error && <Message variant='danger'>{error}</Message>}
</ListGroup.Item>
```

In the above code we check for a error that we get from our [useMutation](https://redux-toolkit.js.org/rtk-query/usage/mutations)
hook. This will be an object though which we cannot render in React, so here we
need the message we sent back from our API server...

```jsx
<ListGroup.Item>
  {error && <Message variant='danger'>{error.data.message}</Message>}
</ListGroup.Item>
```

The same is true for [handling errors from our RTK queries.](https://redux-toolkit.js.org/rtk-query/usage/error-handling)

> Changes can be seen in:-
>
> - [PlaceOrderScreen.jsx](frontend/src/screens/PlaceOrderScreen.jsx)
> - [OrderScreen.jsx](frontend/src/screens/OrderScreen.jsx)
> - [ProductEditScreen.jsx](frontend/src/screens/admin/ProductEditScreen.jsx)
> - [ProductListScreen.jsx](frontend/src/screens/admin/ProductListScreen.jsx)

---

### BUG: After switching users, our new user gets the previous users cart

This is because we store the cart in localStorage and we never clear it when the user logs out.

The solution is to clear the cart in the `authSlice` when the user logs out:

```jsx
logout: (state) => {
  state.userInfo = null;
  // clears cart from local storage
  localStorage.clear();
},
```

> Changes can be seen in [authSlice.js](frontend/src/slices/authSlice.js)

---

### BUG: Passing a string value to our `addDecimals` function

Our `addDecimals` function expects a number and returns a string, but in the `calcPrices` function we are sometimes passing it a string value.

```js
function addDecimals(num) {
  return (Math.round(num * 100) / 100).toFixed(2);
}
```

If you pass a string to `Math.round()` it will coerce it to a number, so it will work, but it's not best practice.

The solution is to ensure we always pass a number to `addDecimals`:

```js
export function calcPrices(orderItems) {
  const itemsPrice = addDecimals(
    orderItems.reduce((acc, item) => acc + item.price * item.qty, 0)
  );
  const shippingPrice = addDecimals(itemsPrice > 100 ? 0 : 10);
  const taxPrice = addDecimals(Number(itemsPrice) * 0.15);
  const totalPrice = (
    Number(itemsPrice) +
    Number(shippingPrice) +
    Number(taxPrice)
  ).toFixed(2);

  return { itemsPrice, shippingPrice, taxPrice, totalPrice };
}
```

> NOTE: the code below has been changed from the course code to fix an issue
> with type coercion of strings to numbers.
> Our addDecimals function expects a number and returns a string, so it is not
> correct to call it passing a string as the argument.

> Changes can be seen in [calcPrices.js](backend/utils/calcPrices.js)

---

### BUG: Token and Cookie expiration not handled in frontend

The cookie and the JWT expire after 30 days.
However for our private routing in the client our react app simply trusts that if we have a user in local storage, then that user is authenticated.
So we have a situation where in the client they can access private routes, but the API calls to the server fail because there is no cookie with a valid JWT.

The solution is to wrap/customize the RTK [baseQuery](https://redux-toolkit.js.org/rtk-query/usage/customizing-queries#customizing-queries-with-basequery) with our own custom functionality that will log out a user on any 401 response

> Changes can be seein in:
>
> - [apiSlice.js](frontend/src/slices/apiSlice.js)

Additionally we can remove the following code:

```js
const expirationTime = new Date().getTime() + 30 * 24 * 60 * 60 * 1000; // 30 days
```

---

### BUG: Calculation of prices as decimals gives odd results

JavaScript has a known issue with floating point arithmetic.

```js
0.1 + 0.2; // 0.30000000000000004
```

The solution is to convert to cents, do our calculations, then convert back to dollars.

The `addDecimals` function does this:

```js
function addDecimals(num) {
  return (Math.round(num * 100) / 100).toFixed(2);
}
```

> Changes can be seen in [calcPrices.js](backend/utils/calcPrices.js)

---

### FAQ: How do I use Vite instead of CRA?

Ok so you're at **Section 1 - Starting The Frontend** in the course and you've
heard cool things about [Vite](https://vitejs.dev/) and why you should use that
instead of [Create React App](https://create-react-app.dev/) in 2023.

There are a few differences you need to be aware of using Vite in place of CRA
here in the course after [scaffolding out your Vite React app](https://github.com/vitejs/vite/tree/main/packages/create-vite#create-vite)

#### Setting up the proxy

Using CRA we have a `"proxy"` setting in our frontend/package.json to avoid
breaking the browser [Same Origin Policy](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy) in development.
In Vite we have to set up our proxy in our
[vite.config.js](https://vitejs.dev/config/server-options.html#server-proxy).

```js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    // proxy requests prefixed '/api' and '/uploads'
    proxy: {
      '/api': 'http://localhost:5000',
      '/uploads': 'http://localhost:5000',
    },
  },
});
```

#### Setting up linting

By default CRA outputs linting from eslint to your terminal and browser console.
To get Vite to ouput linting to the terminal you need to add a [plugin](https://www.npmjs.com/package/vite-plugin-eslint) as a
development dependency...

```bash
npm i -D vite-plugin-eslint
```

Then add the plugin to your **vite.config.js**

```js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
// import the plugin
import eslintPlugin from 'vite-plugin-eslint';

export default defineConfig({
  plugins: [
    react(),
    eslintPlugin({
      // setup the plugin
      cache: false,
      include: ['./src/**/*.js', './src/**/*.jsx'],
      exclude: [],
    }),
  ],
  server: {
    proxy: {
      '/api': 'http://localhost:5000',
      '/uploads': 'http://localhost:5000',
    },
  },
});
```

By default the eslint config that comes with a Vite React project treats some
rules from React as errors which will break your app if you are following Brad exactly.
You can change those rules to give a warning instead of an error by modifying
the **eslintrc.cjs** that came with your Vite project.

```js
module.exports = {
  env: { browser: true, es2020: true },
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:react/jsx-runtime',
    'plugin:react-hooks/recommended',
  ],
  parserOptions: { ecmaVersion: 'latest', sourceType: 'module' },
  settings: { react: { version: '18.2' } },
  plugins: ['react-refresh'],
  rules: {
    // turn this one off
    'react/prop-types': 'off',
    // change these errors to warnings
    'react-refresh/only-export-components': 'warn',
    'no-unused-vars': 'warn',
  },
};
```

#### Vite outputs the build to /dist

Create React App by default outputs the build to a **/build** directory and this is
what we serve from our backend in production.  
Vite by default outputs the build to a **/dist** directory so we need to make
some adjustments to our [backend/server.js](backend/server.js)
Change...

```js
app.use(express.static(path.join(__dirname, '/frontend/build')));
```

to...

```js
app.use(express.static(path.join(__dirname, '/frontend/dist')));
```

and...

```js
app.get('*', (req, res) =>
  res.sendFile(path.resolve(__dirname, 'frontend', 'build', 'index.html'))
);
```

to...

```js
app.get('*', (req, res) =>
  res.sendFile(path.resolve(__dirname, 'frontend', 'dist', 'index.html'))
);
```

#### Vite has a different script to run the dev server

In a CRA project you run `npm start` to run the development server, in Vite you
start the development server with `npm run dev`  
If you are using the **dev** script in your root pacakge.json to run the project
using concurrently, then you will also need to change your root package.json
scripts from...

```json
    "client": "npm start --prefix frontend",
```

to...

```json
    "client": "npm run dev --prefix frontend",
```

Or you can if you wish change the frontend/package.json scripts to use `npm
start`...

```json
    "start": "vite",
```

#### A final note:

Vite requires you to name React component files using the `.jsx` file
type, so you won't be able to use `.js` for your components. The entry point to
your app will be in `main.jsx` instead of `index.js`

And that's it! You should be good to go with the course using Vite.

---

### FIX: issues with LinkContainer

Then instead of using `LinkContainer`:

```jsx
<LinkContainer to='/'>
  <Navbar.Brand>
    <img src={logo} alt='ProShop' />
    ProShop
  </Navbar.Brand>
</LinkContainer>
```

We can remove `LinkContainer` and use the **as** prop on the `Navbar.Brand`

```jsx
<Navbar.Brand as={Link} to='/'>
  <img src={logo} alt='ProShop' />
  ProShop
</Navbar.Brand>
```

> **Changes can be seen in:**
>
> - [Header.jsx](frontend/src/components/Header.jsx)
> - [CheckoutSteps.jsx](frontend/src/components/CheckoutSteps.jsx)
> - [Paginate.jsx](frontend/src/components/Paginate.jsx)
> - [ProfileScreen.jsx](frontend/src/screens/ProfileScreen.jsx)
> - [OrderListScreen.jsx](frontend/src/screens/admin/OrderListScreen.jsx)
> - [ProductListScreen.jsx](frontend/src/screens/admin/ProductListScreen.jsx)
> - [UserListScreen.jsx](frontend/src/screens/admin/UserListScreen.jsx)

After these changes you can then remove **react-router-bootstrap** from your
dependencies in [frontend/package.json](frontend/package.json)

---

## License

The MIT License

Copyright (c) 2023 Traversy Media https://traversymedia.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
