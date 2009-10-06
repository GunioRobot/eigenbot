module Util (
    (+++)
  , appFst
  , calTimeString
  , getCalTime
  , plural
  , generalPlural
  , breakOnSpace
  , dropNewlines
  , delay
  , doForever
  , coin
  , eitherToMaybe
  , maybeIO
  , lookupExn
  , getUrl
  , headUrl
  , probablyUrl
  , simpleHttp
  , safeIndex
) where

import Control.Concurrent (ThreadId, forkIO, threadDelay)
import Control.Monad (forever)
import Data.List (isPrefixOf)
import Data.Map (Map)
import qualified Data.Map as M
import Data.Maybe (fromJust)
import Network.Browser (browse, setAllowRedirects, setMaxRedirects, request)
import Network.HTTP (getRequest, getResponseBody, simpleHTTP)
import Network.HTTP.Base (Response(..), Request(..), RequestMethod(..))
import Network.HTTP.Headers (Header(..))
import System.Time (CalendarTime(..), getClockTime, toCalendarTime)
import Text.Printf(printf)

-- needs shorter name
(+++) :: String -> String -> String
"" +++ "" = ""
s1 +++ "" = s1
"" +++ s2 = s2
s1 +++ s2 = s1 ++ (' ':s2)

calTimeString :: CalendarTime -> String
calTimeString ct =
    printf "%04d-%02d-%02d" (ctYear ct) (fromEnum $ ctMonth ct) (ctDay ct)

getCalTime :: IO CalendarTime
getCalTime = getClockTime >>= toCalendarTime

generalPlural :: String -> String -> Integer -> String
generalPlural one _many 1 = "1" +++ one
generalPlural _one many n = show n +++ many

plural :: String -> Integer -> String
plural one n = generalPlural one (one++"s") n

appFst :: (a -> z) -> (a, b) -> (z, b)
appFst f (one, two) = (f one, two)

breakOnSpace :: String -> (String, String)
breakOnSpace = break (== ' ')

dropNewlines :: String -> String
dropNewlines = map nlToSpace
  where nlToSpace '\n' = ' '
        nlToSpace '\r' = ' '
        nlToSpace c = c

delay :: Int -> IO ()
delay = threadDelay . (* 10^(6::Integer)) -- better way to do this typehint?

doForever :: IO a -> IO ThreadId
doForever = forkIO . forever

coin :: Monad m => m ()
coin = return ()

eitherToMaybe :: Either a b -> Maybe b
eitherToMaybe = either (const Nothing) Just

maybeIO :: (a -> IO ()) -> Maybe a -> IO ()
maybeIO f m = maybe (return ()) f m

lookupExn :: Ord a => a -> Map a b -> b
lookupExn k m = fromJust $ M.lookup k m

-- must be a better way, but example in Network.Browser docs no longer worked
fetchUrl :: String -> RequestMethod -> IO (Response String)
fetchUrl url method = do
      (_, rsp) <- Network.Browser.browse $ do
               setAllowRedirects True -- handle HTTP redirects
               setMaxRedirects $ Just 5
               request $ ((getRequest url) { rqMethod = method })
      return rsp

getUrl :: String -> IO String
getUrl url = fetchUrl url GET >>= getResponseBody . Right

headUrl :: String -> IO [Header]
headUrl url = fetchUrl url HEAD >>= return . rspHeaders

probablyUrl :: String -> Bool
probablyUrl s =
    "http://" `isPrefixOf` s ||
    "https://" `isPrefixOf` s

simpleHttp :: String -> IO String
simpleHttp url = simpleHTTP (getRequest url) >>= getResponseBody

safeIndex :: [a] -> Int -> Maybe a
safeIndex [] _ = Nothing
safeIndex xs i = Just $ xs !! (abs i `mod` length xs)
