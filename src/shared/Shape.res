module Json = Js.Json
module Dict = Js.Dict

type decodeError = string

module Profile = {
  type username = string
  type limit = int
  type offset = int
  type viewMode =
    | Author(username, limit, offset)
    | Favorited(username, limit, offset)
}

module FeedType = {
  type tag = string
  type limit = int
  type offset = int
  type t =
    | Tag(tag, limit, offset)
    | Global(limit, offset)
    | Personal(limit, offset)
}

module Author = {
  type t = {
    username: string,
    bio: option<string>,
    image: string,
    following: option<bool>,
  }

  let decode = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let username =
        obj
        ->Dict.get("username")
        ->Option.flatMap(item => Json.decodeString(item))
        ->Option.getExn
      let bio = obj->Dict.get("bio")->Option.flatMap(item => Json.decodeString(item))
      let image =
        obj->Dict.get("image")->Option.flatMap(item => Json.decodeString(item))->Option.getExn
      let following = obj->Dict.get("following")->Option.flatMap(item => Json.decodeBoolean(item))

      Result.Ok({
        username,
        bio,
        image,
        following,
      })
    } catch {
    | _ => Error("Shape.Author: failed to decode json")
    }
  }
}

module Article = {
  type t = {
    slug: string,
    title: string,
    description: string,
    body: string,
    tagList: array<string>,
    createdAt: Js.Date.t,
    updatedAt: Js.Date.t,
    favorited: bool,
    favoritesCount: int,
    author: Author.t,
  }

  let decode = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let slug =
        obj
        ->Dict.get("slug")
        ->Option.flatMap(item => Json.decodeString(item))
        ->Option.getExn
      let title =
        obj->Dict.get("title")->Option.flatMap(item => Json.decodeString(item))->Option.getExn
      let description =
        obj->Dict.get("description")->Option.flatMap(item => Json.decodeString(item))->Option.getExn
      let body =
        obj
        ->Dict.get("body")
        ->Option.flatMap(item => Json.decodeString(item))
        ->Option.getExn
      let tagList =
        obj
        ->Dict.get("tagList")
        ->Option.flatMap(item => Json.decodeArray(item))
        ->Option.flatMap(tagList => Some(tagList->Array.filterMap(item => Json.decodeString(item))))
        ->Option.getExn
      let createdAt =
        obj
        ->Dict.get("createdAt")
        ->Option.flatMap(item => Json.decodeString(item))
        ->Option.getExn
        ->Js.Date.fromString
      let updatedAt =
        obj
        ->Dict.get("updatedAt")
        ->Option.flatMap(item => Json.decodeString(item))
        ->Option.getExn
        ->Js.Date.fromString
      let favorited =
        obj->Dict.get("favorited")->Option.flatMap(item => Json.decodeBoolean(item))->Option.getExn
      let favoritesCount =
        obj
        ->Dict.get("favoritesCount")
        ->Option.flatMap(item => Json.decodeNumber(item))
        ->Option.getExn
        ->int_of_float
      let author =
        obj
        ->Dict.get("author")
        ->Option.flatMap(author => {
          switch author->Author.decode {
          | Ok(ok) => Some(ok)
          | Error(_err) => None
          }
        })
        ->Option.getExn

      Result.Ok({
        slug,
        title,
        description,
        body,
        tagList,
        createdAt,
        updatedAt,
        favorited,
        favoritesCount,
        author,
      })
    } catch {
    | _ => Error("Shape.Article: failed to decode json")
    }
  }
}

module Articles = {
  type t = {
    articles: array<Article.t>,
    articlesCount: int,
  }

  let decode = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let articles =
        obj
        ->Dict.get("articles")
        ->Option.flatMap(item => Json.decodeArray(item))
        ->Option.flatMap(articles => {
          articles
          ->Array.filterMap(article =>
            switch article->Article.decode {
            | Ok(ok) => Some(ok)
            | Error(_err) => None
            }
          )
          ->Some
        })
        ->Option.getExn
      let articlesCount =
        obj
        ->Dict.get("articlesCount")
        ->Option.flatMap(item => Json.decodeNumber(item))
        ->Option.map(int_of_float)
        ->Option.getExn

      Result.Ok({
        articles,
        articlesCount,
      })
    } catch {
    | _ => Error("Shape.Article: failed to decode json")
    }
  }
}

module Tags = {
  type t = array<string>

  let decode = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let tags =
        obj
        ->Dict.get("tags")
        ->Option.flatMap(item => Json.decodeArray(item))
        ->Option.map(tags => tags->Array.filterMap(item => Json.decodeString(item)))
        ->Option.getExn

      Result.Ok(tags)
    } catch {
    | _ => Error("Shape.Tags: failed to decode json")
    }
  }
}

module User = {
  type t = {
    email: string,
    username: string,
    bio: option<string>,
    image: option<string>,
    token: string,
  }

  let empty = {
    email: "",
    username: "",
    bio: None,
    image: None,
    token: "",
  }

  let decodeUser = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let email =
        obj->Dict.get("email")->Option.flatMap(item => Json.decodeString(item))->Option.getExn
      let username =
        obj->Dict.get("username")->Option.flatMap(item => Json.decodeString(item))->Option.getExn
      let bio = obj->Dict.get("bio")->Option.flatMap(item => Json.decodeString(item))
      let image = obj->Dict.get("image")->Option.flatMap(item => Json.decodeString(item))
      let token =
        obj->Dict.get("token")->Option.flatMap(item => Json.decodeString(item))->Option.getExn

      Result.Ok({
        email,
        username,
        bio,
        image,
        token,
      })
    } catch {
    | _ => Error("Shape.User: failed to decode json")
    }
  }

  let decode = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let user =
        obj
        ->Dict.get("user")
        ->Option.flatMap(user => {
          switch user->decodeUser {
          | Ok(ok) => Some(ok)
          | Error(_err) => None
          }
        })
        ->Option.getExn

      Result.Ok(user)
    } catch {
    | _ => Error("Shape.User: failed to decode json")
    }
  }
}

module CommentUser = {
  type t = {
    username: string,
    bio: option<string>,
    image: string,
    following: bool,
  }

  let decode = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let username =
        obj->Dict.get("username")->Option.flatMap(item => Json.decodeString(item))->Option.getExn
      let bio = obj->Dict.get("bio")->Option.flatMap(item => Json.decodeString(item))
      let image =
        obj
        ->Dict.get("image")
        ->Option.flatMap(item => Json.decodeString(item))
        ->Option.getExn
      let following =
        obj->Dict.get("following")->Option.flatMap(item => Json.decodeBoolean(item))->Option.getExn

      Result.Ok({
        username,
        bio,
        image,
        following,
      })
    } catch {
    | _ => Error("Shape.CommentUser: failed to decode json")
    }
  }
}

module Comment = {
  type t = {
    id: int,
    createdAt: Js.Date.t,
    updatedAt: Js.Date.t,
    body: string,
    author: CommentUser.t,
  }

  let decodeComment = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let id =
        obj
        ->Dict.get("id")
        ->Option.flatMap(item => Json.decodeNumber(item))
        ->Option.map(int_of_float)
        ->Option.getExn
      let createdAt =
        obj
        ->Dict.get("createdAt")
        ->Option.flatMap(item => Json.decodeString(item))
        ->Option.map(item => Js.Date.fromString(item))
        ->Option.getExn
      let updatedAt =
        obj
        ->Dict.get("updatedAt")
        ->Option.flatMap(item => Json.decodeString(item))
        ->Option.map(item => Js.Date.fromString(item))
        ->Option.getExn
      let body =
        obj
        ->Dict.get("body")
        ->Option.flatMap(item => Json.decodeString(item))
        ->Option.getExn
      let author =
        obj
        ->Dict.get("author")
        ->Option.flatMap(author => {
          switch author->CommentUser.decode {
          | Ok(ok) => Some(ok)
          | Error(_err) => None
          }
        })
        ->Option.getExn

      Result.Ok({
        id,
        createdAt,
        updatedAt,
        body,
        author,
      })
    } catch {
    | _ => Error("Shape.Comment: failed to decode json")
    }
  }

  let decode = (json: Json.t): Result.t<array<t>, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let comments =
        obj
        ->Dict.get("comments")
        ->Option.flatMap(item => Json.decodeArray(item))
        ->Option.map(comments => {
          comments->Array.filterMap(comment => {
            switch comment->decodeComment {
            | Ok(ok) => Some(ok)
            | Error(_err) => None
            }
          })
        })
        ->Option.getExn

      Result.Ok(comments)
    } catch {
    | _ => Error("Shape.Comment: failed to decode json")
    }
  }
}

module Settings = {
  type t = {
    email: option<array<string>>,
    bio: option<array<string>>,
    image: option<array<string>>,
    username: option<array<string>>,
    password: option<array<string>>,
  }

  let decode = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let email = obj->Dict.get("email")->Utils.Json.decodeArrayString
      let bio = obj->Dict.get("bio")->Utils.Json.decodeArrayString
      let image = obj->Dict.get("image")->Utils.Json.decodeArrayString
      let username = obj->Dict.get("username")->Utils.Json.decodeArrayString
      let password = obj->Dict.get("password")->Utils.Json.decodeArrayString

      Result.Ok({
        email,
        bio,
        image,
        username,
        password,
      })
    } catch {
    | _ => Error("Shape.Settings: failed to decode json")
    }
  }
}

module Editor = {
  type t = {
    title: option<array<string>>,
    body: option<array<string>>,
    description: option<array<string>>,
  }

  let decode = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let title = obj->Dict.get("title")->Utils.Json.decodeArrayString
      let body = obj->Dict.get("body")->Utils.Json.decodeArrayString
      let description = obj->Dict.get("description")->Utils.Json.decodeArrayString

      Result.Ok({
        title,
        body,
        description,
      })
    } catch {
    | _ => Error("Shape.Editor: failed to decode json")
    }
  }
}

module Login = {
  type t = option<array<string>>

  let decode = (json: Json.t): Result.t<t, decodeError> => {
    try {
      json
      ->Json.decodeObject
      ->Option.getExn
      ->Dict.get("email or password")
      ->Utils.Json.decodeArrayString
      ->Ok
    } catch {
    | _ => Error("Shape.Login: failed to decode json")
    }
  }
}

module Register = {
  type t = {
    email: option<array<string>>,
    password: option<array<string>>,
    username: option<array<string>>,
  }

  let decode = (json: Json.t): Result.t<t, decodeError> => {
    try {
      let obj = json->Json.decodeObject->Option.getExn
      let email = obj->Dict.get("email")->Utils.Json.decodeArrayString
      let username = obj->Dict.get("username")->Utils.Json.decodeArrayString
      let password = obj->Dict.get("password")->Utils.Json.decodeArrayString

      Result.Ok({
        email,
        password,
        username,
      })
    } catch {
    | _ => Error("Shape.Register: failed to decode json")
    }
  }
}
