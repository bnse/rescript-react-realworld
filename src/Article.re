open Relude.Globals;

module TagList = {
  [@react.component]
  let make = (~data: array(string)) => {
    <ul className="tag-list">
      {data
       ->Belt.Array.map(tag =>
           <li key=tag className="tag-default tag-pill tag-outline">
             tag->React.string
           </li>
         )
       ->React.array}
    </ul>;
  };
};

module Comments = {
  [@react.component]
  let make =
      (
        ~slug: string,
        ~data: AsyncResult.t(array(Shape.Comment.t), Error.t),
        ~user: option(Shape.User.t),
        ~onDeleteClick: (~slug: string, ~id: int) => unit,
        ~busy: Belt.Set.Int.t,
      ) => {
    switch (data) {
    | Init
    | Loading
    | Reloading(Error(_)) => <Spinner />
    | Complete(Error(_)) => "ERROR"->React.string
    | Reloading(Ok(comments))
    | Complete(Ok(comments)) =>
      comments
      ->Belt.Array.map((comment: Shape.Comment.t) => {
          let isAPIBusy = Belt.Set.Int.has(busy, comment.id);

          <div className="card" key={comment.id->string_of_int}>
            <div className="card-block">
              <p className="card-text"> comment.body->React.string </p>
            </div>
            <div className="card-footer">
              <Link
                location={Link.profile(~username=comment.author.username)}
                className="comment-author"
                style={ReactDOMRe.Style.make(~marginRight="7px", ())}>
                {switch (comment.author.image) {
                 | "" => <img className="comment-author-img" />
                 | src => <img src className="comment-author-img" />
                 }}
              </Link>
              <Link
                location={Link.profile(~username=comment.author.username)}
                className="comment-author">
                comment.author.username->React.string
              </Link>
              <span className="date-posted">
                {comment.createdAt->Utils.formatDate->React.string}
              </span>
              <span className="mod-options">
                {// TODO: implement "edit" icon
                 false
                   ? <i className="ion-edit" /> : React.null}
                {switch (user) {
                 | Some({username}) when username == comment.author.username =>
                   <i
                     className={isAPIBusy ? "ion-load-a" : "ion-trash-a"}
                     onClick={event =>
                       if (!isAPIBusy && Utils.isMouseRightClick(event)) {
                         onDeleteClick(~slug, ~id=comment.id);
                       }
                     }
                   />
                 | Some(_)
                 | None => React.null
                 }}
              </span>
            </div>
          </div>;
        })
      ->React.array
    };
  };
};

module FavoriteButton = {
  [@react.component]
  let make =
      (
        ~data: AsyncData.t((bool, int, string)),
        ~onClick: Link.onClickAction,
      ) => {
    <Link.Button
      className={
        switch (data) {
        | Init
        | Loading
        | Reloading((false, _, _))
        | Complete((false, _, _)) => "btn btn-sm btn-outline-primary"
        | Reloading((true, _, _))
        | Complete((true, _, _)) => "btn btn-sm btn-primary"
        }
      }
      style={ReactDOMRe.Style.make(~marginLeft="5px", ())}
      onClick={
        switch (data) {
        | Init
        | Loading
        | Reloading((_, _, _)) => Link.Button.customFn(ignore)
        | Complete((_, _, _)) => onClick
        }
      }>
      <i
        className={AsyncData.isBusy(data) ? "ion-load-a" : "ion-heart"}
        style={ReactDOMRe.Style.make(~marginRight="5px", ())}
      />
      {switch (data) {
       | Init
       | Loading => React.null
       | Reloading((favorited, favoritesCount, _slug))
       | Complete((favorited, favoritesCount, _slug)) =>
         <>
           (favorited ? "Unfavorite Article " : "Favorite Article ")
           ->React.string
           <span className="counter">
             {Printf.sprintf("(%d)", favoritesCount)->React.string}
           </span>
         </>
       }}
    </Link.Button>;
  };
};

module FollowButton = {
  [@react.component]
  let make =
      (~data: AsyncData.t((string, bool)), ~onClick: Link.onClickAction) => {
    <Link.Button
      className={
        switch (data) {
        | Init
        | Loading
        | Reloading((_, false))
        | Complete((_, false)) => "btn btn-sm btn-outline-secondary"
        | Reloading((_, true))
        | Complete((_, true)) => "btn btn-sm btn-secondary"
        }
      }
      onClick={
        switch (data) {
        | Init
        | Loading
        | Reloading((_, _)) => Link.Button.customFn(ignore)
        | Complete((_, _)) => onClick
        }
      }>
      <i
        className={AsyncData.isBusy(data) ? "ion-load-a" : "ion-plus-round"}
        style={ReactDOMRe.Style.make(~marginRight="5px", ())}
      />
      {switch (data) {
       | Init
       | Loading => React.null
       | Reloading((username, following))
       | Complete((username, following)) =>
         Printf.sprintf("%s %s", following ? "Unfollow" : "Follow", username)
         ->React.string
       }}
    </Link.Button>;
  };
};

module ArticleDate = {
  [@react.component]
  let make = (~article) => {
    article
    |> AsyncResult.getOk
    |> Option.map((ok: Shape.Article.t) => ok.createdAt)
    |> Option.map(createdAt => createdAt |> Utils.formatDate |> React.string)
    |> Option.getOrElse(React.null);
  };
};

module ArticleAuthorName = {
  [@react.component]
  let make = (~article) => {
    article
    |> AsyncResult.getOk
    |> Option.map((ok: Shape.Article.t) => ok.author)
    |> Option.map((author: Shape.Author.t) =>
         <Link
           location={Link.profile(~username=author.username)}
           className="author">
           {author.username |> React.string}
         </Link>
       )
    |> Option.getOrElse(React.null);
  };
};

module ArticleAuthorAvatar = {
  [@react.component]
  let make = (~article) => {
    article
    |> AsyncResult.getOk
    |> Option.map((ok: Shape.Article.t) => ok.author)
    |> Option.map((author: Shape.Author.t) =>
         <Link location={Link.profile(~username=author.username)}>
           {switch (author.image) {
            | "" => <img />
            | src => <img src />
            }}
         </Link>
       )
    |> Option.getOrElse(React.null);
  };
};

[@react.component]
let make = (~slug: string, ~user: option(Shape.User.t)) => {
  let article = Hook.useArticle(~slug);
  let (comments, busyComments, deleteComment) = Hook.useComments(~slug);
  let (follow, onFollowClick) = Hook.useFollow(~article, ~user);
  let (favorite, onFavoriteClick) = Hook.useFavorite(~article, ~user);

  <div className="article-page">
    <div className="banner">
      <div className="container">
        <h1>
          {article
           |> AsyncResult.getOk
           |> Option.map((ok: Shape.Article.t) => ok.title)
           |> Option.map(title => title |> React.string)
           |> Option.getOrElse(React.null)}
        </h1>
        <div className="article-meta">
          <ArticleAuthorAvatar article />
          <div className="info">
            <ArticleAuthorName article />
            <span className="date"> <ArticleDate article /> </span>
          </div>
          <FollowButton data=follow onClick=onFollowClick />
          <FavoriteButton data=favorite onClick=onFavoriteClick />
        </div>
      </div>
    </div>
    <div className="container page">
      <div className="row article-content">
        <div className="col-md-12">
          <div style={ReactDOMRe.Style.make(~marginBottom="2rem", ())}>
            {switch (article) {
             | Init
             | Loading => <Spinner />
             | Reloading(Ok({body}))
             | Complete(Ok({body})) =>
               <div
                 dangerouslySetInnerHTML={
                   "__html": EscapeHatch.markdownToHtml(body),
                 }
               />
             | Reloading(Error(_error))
             | Complete(Error(_error)) => "ERROR"->React.string
             }}
          </div>
          {switch (article) {
           | Init
           | Loading
           | Reloading(Error(_))
           | Complete(Error(_)) => React.null
           | Reloading(Ok({tagList}))
           | Complete(Ok({tagList})) => <TagList data=tagList />
           }}
        </div>
      </div>
      <hr />
      <div className="article-actions">
        <div className="article-meta">
          <ArticleAuthorAvatar article />
          <div className="info">
            <ArticleAuthorName article />
            <span className="date"> <ArticleDate article /> </span>
          </div>
          <FollowButton data=follow onClick=onFollowClick />
          <FavoriteButton data=favorite onClick=onFavoriteClick />
        </div>
      </div>
      <div className="row">
        <div className="col-xs-12 col-md-8 offset-md-2">
          {switch (user) {
           | Some({image}) =>
             <form className="card comment-form">
               <div className="card-block">
                 <textarea
                   className="form-control"
                   placeholder="Write a comment..."
                   rows=3
                 />
               </div>
               <div className="card-footer">
                 {switch (image) {
                  | "" => <img className="comment-author-img" />
                  | src => <img src className="comment-author-img" />
                  }}
                 <button className="btn btn-sm btn-primary">
                   /* TODO: implement "click" action */
                    "Post Comment"->React.string </button>
               </div>
             </form>
           | None =>
             <p>
               <Link className="nav-link" location=Link.login>
                 "Sign in"->React.string
               </Link>
               " or "->React.string
               <Link className="nav-link" location=Link.register>
                 "sign up"->React.string
               </Link>
               " to add comments on this article."->React.string
             </p>
           }}
          <Comments
            slug
            data=comments
            busy=busyComments
            user
            onDeleteClick=deleteComment
          />
        </div>
      </div>
    </div>
  </div>;
};
