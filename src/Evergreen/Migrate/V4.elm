module Evergreen.Migrate.V4 exposing (..)

import Dict
import Evergreen.V3.Data.Entry
import Evergreen.V3.Data.Store
import Evergreen.V3.Types as Old
import Evergreen.V4.Data.Entry
import Evergreen.V4.Data.Store
import Evergreen.V4.Types as New
import Lamdera.Migrations exposing (..)
import Sha256


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    ModelMigrated
        ( { sessions =
                old.sessions
                    |> Dict.map
                        (\_ session ->
                            { userId = updateId session.userId
                            , expires = session.expires
                            }
                        )
          , users =
                { items =
                    old.users.items
                        |> Dict.map
                            (\k user ->
                                { username = String.toLower user.username
                                , bio = user.bio
                                , image = user.image
                                , passwordHash = Sha256.sha256 user.password
                                , trackers = user.trackers |> List.map updateId
                                }
                            )
                , nextId = old.users.nextId
                }
          , trackers = old.trackers
          , usernames =
                old.usernames
                    |> Dict.toList
                    |> List.map (\( k, v ) -> ( String.toLower k, updateId v ))
                    |> Dict.fromList
          , drafts =
                old.drafts
                    |> Dict.map (\_ ( p, z, e ) -> ( p, z, updateContent e ))
          , entries =
                old.entries
                    |> Dict.map (\_ dict -> dict |> Dict.map (\_ -> updateContent))
          , following = old.following |> Dict.map (\_ -> List.map updateId)
          , hour = old.hour
          }
        , Cmd.none
        )


updateId (Evergreen.V3.Data.Store.Id id) =
    Evergreen.V4.Data.Store.unsafeWrite id


updateContent entity =
    { content = entity.content
    , description = entity.description
    , link = Nothing
    }


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    MsgOldValueIgnored


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    MsgOldValueIgnored


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgOldValueIgnored
