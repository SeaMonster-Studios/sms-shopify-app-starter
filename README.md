# SMS Shopify App Stater (ReasonML, Hasura, Serverless, Netlify, Sentry)

This is a starter repo for quickly getting up and running with a Shopify app. Lambda functions are included to handle installation, authentication, and authorization in conjunction with Shopify's OAuth process and with Hasura for storing a permenant access token, shop origin, and any other details.

## Technology Choices 
- ReasonML for UI and Serverless lambda functions
- Hasura for Database & GraphQL API
- Serverless framework for developing and deploying lambda functions
- Netlify for hosting static UI

## Getting Started
1. Clone the project and run `yarn` to install the project dependencies.
2. Rename the .env.example file to .env.
3. From your Shopify partner portal create a new app. Grab the API key and API secret key and put them in the .env file.
4. Put the [shopify scopes](https://shopify.dev/docs/admin-api/access-scopes) you need as comma separated values within the .env file. Keep in mind that if you need write access to a scope, you do NOT need to list the read access to that same scope. If you do, installation will fail b/c Shopify will strip the read access scope from the list and scopes during the installation will not match.
5. Create a new site on netlify connected to your fork of this repo. The site will not build at this point.
6. If you'd like to use Sentry.io for error reporting create a new app and then put the provided DSN url in the .env file. Also, on the production server (netlify), be sure to set SENTRY_ENV to production. If you're working locally this should be set to something else so that errors during development are not reported.
7. Create a new Hasura instance for your app. [You can quickly get started by deploying to heroku here.](https://hasura.io/docs/1.0/graphql/manual/getting-started/heroku-simple.html)
    - Setup a users table with `id` (text) and `accessToken` (text) columns. The id of the user will be the shopify store. The accessToken is a permenant token shopify provides to a store during the installation process.
8. Secure your graphql endpoint by following the instructions [here](https://hasura.io/docs/1.0/graphql/manual/deployment/heroku/securing-graphql-endpoint.html) and then put your HASURA_ADMIN_SECRET in the .env file.
9. Fetch your GraphQL schema from Hasura by running `yarn get:schema`. You can also do this at a later time after your schema has changed. Commit the schema and push the changes to trigger a build on Netlify. The app should have no problem building at this point.
10. Head back to your netlify dashboard. Once the build has completed grab the app's URL and put in the .env file. 
11. Run `sls login` to log into your serverless account via the cli. This will bring you to your serverless dashboard where you will create a new serverless app. After doing so, update the `org`, `app`, and `service.name` settings in `serverless.yml` to match the app you just created.
12. Deploy the pre-configured lambdas by running `yarn deploy:lambda`. Be sure to copy the URLs to the lambdas and set them aside.
13. Provide authorization via webhook in Hasura with the `authWebHook` lambda you just deployed. You can do this by setting the `HASURA_GRAPHQL_AUTH_HOOK` environment variable within the Heroku instance to the authWebHook lambda URL provided in the terminal output in the previous step.
14. Go back to the dashboard of your app within your partner portal. Click on App Setup.
    - Set the `App URL` to the `install` lambda's URL
    - Set the `Whitelisted redirection URL(s)` to the `getToken` lambda's URL as well as `http://localhost:3000/dev/getToken` so that you can run the install process outside of the Shopify App Stored.
15. Install your app
    - a. via Shopify 
        - Go to your Apps dashboard within your partner portal and click on "Test on development store" and then select the store you'd like to test the app on.
    - b. Install your app via localhost
        - Run `yarn start` to startup bucklescript, netlify dev, and serverless offline.
        - Go to the following URL (but replace YOUR_TEST_STORE with your test store's name): http://localhost:3000/dev/install?shop=YOUR_TEST_STORE.myshopify.com&redirect=http://localhost:3000/dev/getToken
16. Viewing your app post installation:
    - You can view the published version within your shopify test store
    - You can view it locally, but you'll first need to look within your Hasura DB to get the access token associated with your store, then use the following URL: http://localhost:8222/?shop=YOUR_TEST_STORE.myshopify.com&accessToken=YOUR_ACCESS_TOKEN&apiKey=YOUR_SHOPIFY_APP_API_Key

## Resources

### Authorization and authWebHook lambda
- https://hasura.io/docs/1.0/graphql/manual/auth/authentication/webhook.html
- https://github.com/hasura/graphql-engine/blob/master/community/boilerplates/auth-webhooks/nodejs-express/server.js
- https://hasura.io/blog/hasura-authentication-explained/

### Hasura
- [Getting Started](https://hasura.io/docs/1.0/graphql/manual/getting-started/index.html)
- [Setting up User Permissions](https://hasura.io/docs/1.0/graphql/manual/auth/authorization/permission-rules.html)

## Roadmap

- Implement webhook in shopify where if user deletes the app, we remove their data from hasura (https://shopify.dev/docs/admin-api/rest/reference/events/webhook?api[version]=2020-04)
- Implement shopify payment side of things
- Implement tailwind for styles