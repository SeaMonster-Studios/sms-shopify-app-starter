type fetch<'s, 'f> =
  | NotAsked
  | Loading
  | Failure('f)
  | Success('s)

type shopifyAuthed = {
  accessToken: string,
  shop: string,
  apiKey: string,
}
