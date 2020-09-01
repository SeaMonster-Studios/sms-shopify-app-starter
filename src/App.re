open FUtils;
open Belt;

module Inner = {
  [@react.component]
  let make = () => {
    let (simple, _full) =
      ApolloHooks.useQuery(ShopQueries.GetAuthedShop.definition);
    switch (simple) {
    | Loading => "Loading hasura shop"->str
    | Data(data) =>
      switch (data##shops->Array.get(0)) {
      | None => "Shop not found"->str
      | Some(shop) =>
        <div>
          <h1> "Shop data from hasura"->str </h1>
          <p> "Store: "->str {shop##id->str} </p>
          <p> "Shopify Access Token: "->str {shop##accessToken->str} </p>
        </div>
      }
    | Error(errors) =>
      Js.log(errors);
      "Errors fetching shop from hasura"->str;
    | NoData => "No shop data in hasura"->str
    };
  };
};

module AuthedContainer = {
  [@react.component]
  let make = (~shopifyAuthed: Types.shopifyAuthed) => {
    <ShopifyPolaris.Provider>
      <ShopifyBridge.Provider
        config=ShopifyBridge.(
          config(
            ~apiKey=shopifyAuthed.apiKey,
            ~shopOrigin=shopifyAuthed.shop,
            (),
          )
        )>
        <ShopifyBridge.Loading />
        <ShopifyPolaris.Card />
        <Inner />
      </ShopifyBridge.Provider>
    </ShopifyPolaris.Provider>;
  };
};

[@react.component]
let make = () => {
  let appStore = React.useContext(AppStore.context);

  switch (appStore.shopify) {
  | NotAsked
  | Loading => <Loader.Screen />
  | Failure(message) => <ErrorScreen> message->str </ErrorScreen>
  | Success(shopifyAuthed) => <AuthedContainer shopifyAuthed />
  };
};