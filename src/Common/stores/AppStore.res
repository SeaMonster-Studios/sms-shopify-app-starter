open Belt
open FUtils

module Hasura = {
  let inMemoryCache = ApolloInMemoryCache.createInMemoryCache()

  let makeClient = (~uri, accessToken) => {
    /* Create an HTTP Link */
    let httpLink = ApolloLinks.createHttpLink(
      ~uri,
      ~headers={"Shopify-Access-Token": accessToken}->Obj.magic,
      (),
    )

    ReasonApollo.createApolloClient(~link=httpLink, ~cache=inMemoryCache, ())
  }
}

type state = {shopify: Types.fetch<Types.shopifyAuthed, string>}

let initialState = {shopify: Loading}

module Utils_ = {
  let parseUrlSearch = search => {
    let map = search->Js.String2.split("&")->Array.reduce(Map.String.empty, (acc, param) => {
      let parts = param->Js.String2.split("=")
      switch (parts->Array.get(0), parts->Array.get(1)) {
      | (Some(name), Some(value)) => Map.String.set(acc, name, value)
      | _ => acc
      }
    })

    switch (
      map->Map.String.get("shop"),
      map->Map.String.get("accessToken"),
      map->Map.String.get("apiKey"),
    ) {
    | (Some(shop), Some(accessToken), Some(apiKey)) =>
      Types.Success(({shop: shop, accessToken: accessToken, apiKey: apiKey}: Types.shopifyAuthed))
    | _ =>
      Sentry.captureMessage(
        "Could not successfully parse shop, accessToken, and apiKey. Search params: " ++ search,
      )
      Failure("Error. Authentication Failed.")
    }
  }
}

let context = React.createContext(initialState)

module ContextProvider = {
  let make = React.Context.provider(context)
  let makeProps = (~value: state, ~children, ()) =>
    {
      "value": value,
      "children": children,
    }
}

@react.component
let make = (~children) => {
  let url = ReasonReactRouter.useUrl()
  let (value, setValue) = React.useState(() => initialState)

  React.useEffect2(() => {
    switch value.shopify {
    | Success(_) => ()
    | _ => setValue(_value => {shopify: url.search->Utils_.parseUrlSearch})
    }

    None
  }, (url.search, value.shopify))

  <ContextProvider value>
    {switch (value.shopify, SharedUtils.graphEndpoint) {
    | (Success(shopifyAuthed), Some(uri)) =>
      let client = shopifyAuthed.accessToken->Hasura.makeClient(~uri)
      <ReasonApollo.Provider client>
        <ApolloHooks.Provider client> children </ApolloHooks.Provider>
      </ReasonApollo.Provider>
    | _ => children
    }}
  </ContextProvider>
}
