open Belt
open Lambda
open SharedUtils

module SS = SeamonsterStudiosReason
module Sentry = {
  include Sentry
  include SentryNode
}

let headersBase = Lambda.headers(~allowOrigin="*", ~allowCredentials=true)

let headers = headersBase()

let toOp = Js.Nullable.toOption

@bs.val @bs.scope(("process", "env"))
external apiKey: Js.Nullable.t<string> = "SHOPIFY_API_KEY"
let apiKey = apiKey->Js.Nullable.toOption

@bs.val @bs.scope(("process", "env"))
external apiSecret: Js.Nullable.t<string> = "SHOPIFY_SECRET"
let apiSecret = apiSecret->Js.Nullable.toOption

@bs.val @bs.scope(("process", "env"))
external scopes: Js.Nullable.t<string> = "SHOPIFY_SCOPES"
let scopes = scopes->Js.Nullable.toOption

@bs.val @bs.scope(("process", "env"))
external hasuraAdminSecret: Js.Nullable.t<string> = "HASURA_ADMIN_SECRET"
let hasuraAdminSecret = hasuraAdminSecret->Js.Nullable.toOption

@bs.val @bs.scope(("process", "env"))
external appUrl: Js.Nullable.t<string> = "APP_UI_URL"
let appUrl = appUrl->Js.Nullable.toOption

@bs.val @bs.scope(("process", "env"))
external redirectUrl: Js.Nullable.t<string> = "SHOPIFY_REDIRECT_URL"
let redirectUrl = redirectUrl->Js.Nullable.toOption

module GraphQL = {
  @bs.module external fetch: ApolloClient.fetch = "isomorphic-fetch"

  module Client = {
    open ApolloInMemoryCache
    let inMemoryCache = createInMemoryCache()
    let uri = graphEndpoint->Option.getWithDefault("")
    let httpLink = ApolloLinks.createHttpLink(
      ~uri,
      ~fetch,
      ~headers={
        "x-hasura-admin-secret": hasuraAdminSecret->Belt.Option.getWithDefault(""),
      }->Obj.magic,
      (),
    )
    let instance = ReasonApollo.createApolloClient(~link=httpLink, ~cache=inMemoryCache, ())
  }

  type response = {"data": Js.Nullable.t<Js.Json.t>}

  external toApolloResult: 'a => response = "%identity"
}

module FutureUtils = {
  let fromOptional = optional =>
    optional->Option.mapWithDefault(Future.make(r => (400, "")->Result.Error->r), value =>
      Future.make(r => value->Result.Ok->r)
    )

  let fromNullable = nullable => nullable->Js.Nullable.toOption->fromOptional

  let toError = data => Future.make(r => data->Error->r)
}

switch (sentryEnv, sentryDsn) {
| (Some(environment), Some(dsn)) =>
  if sentryEnv->Option.getWithDefault("") == "production" {
    open Sentry
    make(
      options(
        ~dsn,
        ~environment,
        ~ignoreErrors=[%re("/.*localhost.* /")],
        ~blacklistUrls=[%re("/.*localhost.* /")],
        (),
      )->Js.Nullable.return,
    )
  }
| _ =>
  Js.log(
    "SENTRY_DSN and/or SENTRY_ENV environment variables are missing. Please add them to ensure reporting is working correctly for Sentry in production",
  )
}

module Verify = {
  %%private(
    @ocaml.doc(
      "Shopify requires you to compare hmac w/all query params in the url except for the `hmac`. They also warn that those params can change over time, so we need to do this dynamically "
    )
    let queryParamsWithoutHMAC: queryStringParameters => string = %raw(
      `
   function (params) {
    return Object.keys(params).reduce((acc, key) => key === "hmac" ? acc : [...acc, \`\${key}=\${params[key]}\`], []).join("&")
  }
`
    )
  )
  let env = () =>
    switch (apiKey, apiSecret, scopes, hasuraAdminSecret, appUrl, redirectUrl) {
    | (
        Some(apiKey),
        Some(apiSecret),
        Some(scopes),
        Some(hasuraAdminSecret),
        Some(appUrl),
        Some(redirect),
      ) =>
      Result.Ok({
        apiKey: apiKey,
        apiSecret: apiSecret,
        scopes: scopes,
        hasuraAdminSecret: hasuraAdminSecret,
        appUrl: appUrl,
        redirect: redirect,
      })
    | _ =>
      let apiKey = apiKey->Option.getWithDefault("")
      let apiSecret = apiSecret->Option.getWithDefault("")
      let scopes = scopes->Option.getWithDefault("")
      let hasuraAdminSecret = hasuraAdminSecret->Option.getWithDefault("")
      let appUrl = appUrl->Option.getWithDefault("")
      Sentry.captureMessage(
        j`App installation error. Missing one more environment variables. Actually received:
        SHOPIFY_API_KEY: $apiKey
        SHOPIFY_SECRET: $apiSecret
        SHOPIFY_SCOPES: $scopes
        HASURA_ADMIN_SECRET: $hasuraAdminSecret
        APP_UI_URL: $appUrl (This is dynamically configured within \`serverless.yml\``,
      )
      Result.Error("App Initialization Error")
    }

  let paramsError = "Missing necessary query parameters. The `shop` parameter must always be present. If you're installing the app locally then a `redirect` paremeter should also be provided. It the app has already been installed then an `hmac` along with other parameters need to be provided by shopify."

  let params = (params: Js.Nullable.t<queryStringParameters>) =>
    params
    ->Js.Nullable.toOption
    ->Option.mapWithDefault(Result.Error(paramsError), params => Result.Ok(params))

  let hmac = (~hmac, ~apiSecret, ~params) => {
    let providedHmac = hmac->Node.Buffer.fromStringWithEncoding(#utf8)
    let generatedHash = {
      open Crypto
      createHmac("sha256", apiSecret)->update(params->queryParamsWithoutHMAC)->digest("hex")
    }->Node.Buffer.fromStringWithEncoding(#utf8)

    generatedHash->Crypto.timingSafeEqual(providedHmac)
  }

  let shop = shop =>
    %re("/[a-zA-Z0-9][a-zA-Z0-9\-]*\.myshopify\.com[\/]?/")
    ->Js.String.match_(shop)
    ->Belt.Option.mapWithDefault(false, match_ => match_->Array.length > 0)

  let request = (params_: Js.Nullable.t<queryStringParameters>) =>
    env()
    ->Result.flatMap(env => params_->params->Result.map(params => (env, params)))
    ->Result.flatMap(((env, params)) => {
      let isInstalled =
        params.session->Js.Nullable.toOption->Option.mapWithDefault(false, _ => true)
      switch (params.shop->Js.Nullable.toOption, params.hmac->Js.Nullable.toOption) {
      | (Some(shop), Some(hmac_)) =>
        @ocaml.doc(
          " if the app hasn't been installed or run through the shopify /admin/oauth/access_token request, hmac wont be provided. Otherwise it is and needs to be verified  "
        )
        hmac(~hmac=hmac_, ~params, ~apiSecret=env.apiSecret)
          ? Result.Ok({env: env, params: params, isInstalled: isInstalled, shop: shop})
          : Result.Error("hmac verification failed")
      | (Some(shop_), None) =>
        shop_->shop
          ? Result.Ok({env: env, params: params, isInstalled: isInstalled, shop: shop_})
          : Result.Error(j`$shop is not a valid shopify store`)
      | (None, _) => Result.Error(paramsError)
      }
    })
}
