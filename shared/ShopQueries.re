module GetShop = [%graphql
  {|
    query getShop ($id: String!) {
    shops(where: {id: {_eq: $id}}) {
        id
        accessToken
      }
    }
  |}
];

module GetAuthedShop = [%graphql
  {|
    query getShop  {
    shops {
        id
        accessToken
      }
    }
  |}
];

module CreateShop = [%graphql
  {|
  mutation CreateShop ($id: String!, $accessToken: String!) {
     insert_shops_one(object: {accessToken: $accessToken, id: $id}) {
      id
    }
  }
|}
];