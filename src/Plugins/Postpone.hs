        module Plugins.Postpone (plugin) where

import Control.Monad (forM_)
import Control.Monad.Trans (liftIO)
import Control.Monad.State.Strict (get, put)
import Data.Map (Map)
import qualified Data.Map as M
import System.Time (CalendarTime)
import Text.Printf (printf)

import qualified Base as B
import Util (calTimeString, getCalTime, insertAppend)

data MsgKey = MsgKey B.Channel B.Nick
              deriving (Eq, Ord)

type PluginState = Map MsgKey [SavedMsg]

data SavedMsg = SM {
      _smFrom :: B.Nick
    , _smTo :: B.Nick
    , _smMsg :: String
    , _smDate :: CalendarTime
}

initState :: PluginState
initState = M.empty

plugin :: B.Plugin
plugin = B.genPlugin
           "postpone plugin: ![postpone|pp] <user> <msg>"
           loop
           initState

loop :: B.PluginLoop PluginState
loop evq actq = do
    saveMap <- get
    ev <- liftIO $ B.readEvent evq
    case ev of
      B.ChannelMsg chan nick msg -> do
        case words msg of
          "!postpone":user:rest -> do
              time <- liftIO getCalTime
              let saved = SM nick user (unwords rest) time
                  key = MsgKey chan user
              put $ insertAppend key saved saveMap
              liftIO $ B.say actq chan (printf "message for %s saved" user)
          _ -> return ()
      B.Join chan nick ->
        let key = MsgKey chan nick in
        case M.lookup key saveMap of
          Nothing -> return ()
          Just saved -> do
            liftIO $ forM_ saved sendSaved
            put $ M.delete key saveMap
              where sendSaved (SM from to msg time) =
                      B.say actq chan $ printf "from %s on %s: %s: %s"
                        from (calTimeString time) to msg
      _ -> return ()
