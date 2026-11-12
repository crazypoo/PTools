// English: Unified metadata for every application descriptor absorbed into PTools.
// Español: Metadatos unificados para todos los descriptores absorbidos en PTools.
// 中文：统一记录 PTools 吸收的全部应用描述器元数据。

public extension PTApplicationCatalog {
    /// The complete 172-application catalog; actions remain available on `Applications` types.
    /// Catálogo completo de 172 aplicaciones; las acciones siguen disponibles en los tipos `Applications`.
    /// 完整的 172 个应用目录；具体 Action 仍通过 `Applications` 下的类型提供。
    static let all: [PTApplicationDescriptor] = [
        PTApplicationDescriptor(
            identifier: "air-launch",
            scheme: "airlaunch:",
            fallbackURL: "http://www.iosappdownload.org/download.php?boaID=846864",
            appStoreID: "993479740"
        ),
        PTApplicationDescriptor(
            identifier: "ali-express",
            scheme: "aliexpress:",
            fallbackURL: "http://www.aliexpress.com",
            appStoreID: "436672029"
        ),
        PTApplicationDescriptor(
            identifier: "all-cast",
            scheme: "allCast:",
            fallbackURL: "http://www.allcast.io",
            appStoreID: "943763227"
        ),
        PTApplicationDescriptor(
            identifier: "app-settings",
            scheme: "app-settings:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "app-store",
            scheme: "itms-apps:",
            fallbackURL: "https:",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "apple-maps",
            scheme: "maps:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "apple-watch",
            scheme: "itms-watch:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "audible",
            scheme: "Audible:",
            fallbackURL: "http://www.audible.com/",
            appStoreID: "379693831"
        ),
        PTApplicationDescriptor(
            identifier: "ayah",
            scheme: "ayah:",
            fallbackURL: "http://ayahapp.com",
            appStoreID: "706037876"
        ),
        PTApplicationDescriptor(
            identifier: "behance",
            scheme: "behance:",
            fallbackURL: "https://www.behance.net/",
            appStoreID: "489667151"
        ),
        PTApplicationDescriptor(
            identifier: "bnr",
            scheme: "bnr:",
            fallbackURL: "http://www.bnr.nl",
            appStoreID: "433128088"
        ),
        PTApplicationDescriptor(
            identifier: "box",
            scheme: "box:",
            fallbackURL: "https://www.box.com/business/secure-enterprise-mobility/",
            appStoreID: "290853822"
        ),
        PTApplicationDescriptor(
            identifier: "buzzfeed",
            scheme: "buzzfeed:",
            fallbackURL: "http://www.buzzfeed.com",
            appStoreID: "352969997"
        ),
        PTApplicationDescriptor(
            identifier: "calendars",
            scheme: "calendarslite:",
            fallbackURL: "https://readdle.com/products/calendars5",
            appStoreID: "608834326"
        ),
        PTApplicationDescriptor(
            identifier: "camera360",
            scheme: "camera360:",
            fallbackURL: "https://www.camera360.com/production/?production=camera360&platform=ios",
            appStoreID: "443354861"
        ),
        PTApplicationDescriptor(
            identifier: "careem",
            scheme: "careem:",
            fallbackURL: "https://www.careem.com/dubai/node",
            appStoreID: "592978487"
        ),
        PTApplicationDescriptor(
            identifier: "chromecast",
            scheme: "chromecast:",
            fallbackURL: "https://www.google.com/intl/en_us/chromecast/",
            appStoreID: "680819774"
        ),
        PTApplicationDescriptor(
            identifier: "circle-pay",
            scheme: "circle:",
            fallbackURL: "https://www.circle.com/",
            appStoreID: "920164002"
        ),
        PTApplicationDescriptor(
            identifier: "clips",
            scheme: "clips:",
            fallbackURL: "http://www.cleanshavenapps.com/clips/#download",
            appStoreID: "917638056"
        ),
        PTApplicationDescriptor(
            identifier: "cnet",
            scheme: "cnet:",
            fallbackURL: "http://www.cnet.com",
            appStoreID: "383989837"
        ),
        PTApplicationDescriptor(
            identifier: "cnn",
            scheme: "cnn:",
            fallbackURL: "http://edition.cnn.com/specials/mobile-apps",
            appStoreID: "331786748"
        ),
        PTApplicationDescriptor(
            identifier: "currency",
            scheme: "Currency:",
            fallbackURL: "http://www.xe.com/apps/iphone/",
            appStoreID: "315241195"
        ),
        PTApplicationDescriptor(
            identifier: "daily-motion",
            scheme: "dailymotion:",
            fallbackURL: "http://www.dailymotion.com/",
            appStoreID: "336978041"
        ),
        PTApplicationDescriptor(
            identifier: "dama-king",
            scheme: "damaking:",
            fallbackURL: "http://level3.io",
            appStoreID: "442570707"
        ),
        PTApplicationDescriptor(
            identifier: "day-cost",
            scheme: "DayCost:",
            fallbackURL: "https://www.facebook.com/iDaycost/",
            appStoreID: "979953415"
        ),
        PTApplicationDescriptor(
            identifier: "day-one",
            scheme: "dayone:",
            fallbackURL: "http://dayoneapp.com/",
            appStoreID: "421706526"
        ),
        PTApplicationDescriptor(
            identifier: "diigo",
            scheme: "diigo:",
            fallbackURL: "https://www.diigo.com",
            appStoreID: "933773981"
        ),
        PTApplicationDescriptor(
            identifier: "documents",
            scheme: "rdocs:",
            fallbackURL: "https://readdle.com/products/documents/",
            appStoreID: "364901807"
        ),
        PTApplicationDescriptor(
            identifier: "dropbox",
            scheme: "dbapi-2:",
            fallbackURL: "https://dropbox.com/",
            appStoreID: "327630330"
        ),
        PTApplicationDescriptor(
            identifier: "duolingo",
            scheme: "duolingo:",
            fallbackURL: "https://www.duolingo.com",
            appStoreID: "570060128"
        ),
        PTApplicationDescriptor(
            identifier: "ebay",
            scheme: "eBay:",
            fallbackURL: "http://www.ebay.com/",
            appStoreID: "282614216"
        ),
        PTApplicationDescriptor(
            identifier: "echofon",
            scheme: "echofon:",
            fallbackURL: "http://www.echofon.com",
            appStoreID: "286756410"
        ),
        PTApplicationDescriptor(
            identifier: "epson",
            scheme: "com.epson.iPrint:",
            fallbackURL: "https://www.epson.com/cgi-bin/Store/jsp/epson-connect/mobile-printing/iprint-app.do",
            appStoreID: "326876192"
        ),
        PTApplicationDescriptor(
            identifier: "everypost",
            scheme: "everypost:",
            fallbackURL: "http://everypost.me",
            appStoreID: "572530903"
        ),
        PTApplicationDescriptor(
            identifier: "eye-em",
            scheme: "eyeem:",
            fallbackURL: "https://www.eyeem.com/community",
            appStoreID: "445638931"
        ),
        PTApplicationDescriptor(
            identifier: "face-time",
            scheme: "facetime:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "face-time-audio",
            scheme: "facetime-audio:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "facebook",
            scheme: "fb:",
            fallbackURL: "https://www.facebook.com/",
            appStoreID: "284882215"
        ),
        PTApplicationDescriptor(
            identifier: "feedly",
            scheme: "feedly:",
            fallbackURL: "http://feedly.com/i/welcome",
            appStoreID: "396069556"
        ),
        PTApplicationDescriptor(
            identifier: "file-app",
            scheme: "fileapp:",
            fallbackURL: "http://fileapp.com",
            appStoreID: "297804694"
        ),
        PTApplicationDescriptor(
            identifier: "find-friends",
            scheme: "FindMyFriends:",
            fallbackURL: "",
            appStoreID: "466122094"
        ),
        PTApplicationDescriptor(
            identifier: "findi-phone",
            scheme: "fmip1:",
            fallbackURL: "https://itunes.apple.com/us/app/find-my-iphone/id376101648?mt=8",
            appStoreID: "376101648"
        ),
        PTApplicationDescriptor(
            identifier: "fitbit",
            scheme: "fitbit:",
            fallbackURL: "https://www.fitbit.com/app",
            appStoreID: "462638897"
        ),
        PTApplicationDescriptor(
            identifier: "flickr",
            scheme: "Flickr:",
            fallbackURL: "https://www.flickr.com/",
            appStoreID: "328407587"
        ),
        PTApplicationDescriptor(
            identifier: "flipboard",
            scheme: "Flipboard:",
            fallbackURL: "https://flipboard.com",
            appStoreID: "358801284"
        ),
        PTApplicationDescriptor(
            identifier: "flipps-tv",
            scheme: "flippshd:",
            fallbackURL: "http://www.flipps.com",
            appStoreID: "348147113"
        ),
        PTApplicationDescriptor(
            identifier: "forest",
            scheme: "Forest:",
            fallbackURL: "https://www.forestapp.cc/en/",
            appStoreID: "866450515"
        ),
        PTApplicationDescriptor(
            identifier: "foursquare",
            scheme: "foursquare:",
            fallbackURL: "https://foursquare.com/download",
            appStoreID: "306934924"
        ),
        PTApplicationDescriptor(
            identifier: "friendly-social",
            scheme: "friendly-chrome-x-success:",
            fallbackURL: "http://friendly.io",
            appStoreID: "400169658"
        ),
        PTApplicationDescriptor(
            identifier: "fril",
            scheme: "fril:",
            fallbackURL: "https://fril.jp/",
            appStoreID: "523497998"
        ),
        PTApplicationDescriptor(
            identifier: "gallery",
            scheme: "photos-redirect:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "glympse",
            scheme: "glympse:",
            fallbackURL: "https://glympse.com/get-glympse",
            appStoreID: "330316698"
        ),
        PTApplicationDescriptor(
            identifier: "google-calendar",
            scheme: "com.google.calendar:",
            fallbackURL: "https://www.google.com/calendar/about/",
            appStoreID: "909319292"
        ),
        PTApplicationDescriptor(
            identifier: "google-chrome",
            scheme: "googlechrome:",
            fallbackURL: "https://www.google.com/chrome/",
            appStoreID: "535886823"
        ),
        PTApplicationDescriptor(
            identifier: "google-docs",
            scheme: "googledocs:",
            fallbackURL: "http://www.google.com/docs/about/",
            appStoreID: "842842640"
        ),
        PTApplicationDescriptor(
            identifier: "google-drive",
            scheme: "googledrive:",
            fallbackURL: "https://www.google.com/drive/",
            appStoreID: "507874739"
        ),
        PTApplicationDescriptor(
            identifier: "google-earth",
            scheme: "kml:",
            fallbackURL: "https://www.google.com/earth/",
            appStoreID: "293622097"
        ),
        PTApplicationDescriptor(
            identifier: "google-mail",
            scheme: "googlegmail:",
            fallbackURL: "https://mail.google.com/",
            appStoreID: "422689480"
        ),
        PTApplicationDescriptor(
            identifier: "google-maps",
            scheme: "comgooglemaps:",
            fallbackURL: "https://maps.google.com/",
            appStoreID: "585027354"
        ),
        PTApplicationDescriptor(
            identifier: "google-photos",
            scheme: "googlephotos:",
            fallbackURL: "https://www.google.com/photos/about/",
            appStoreID: "962194608"
        ),
        PTApplicationDescriptor(
            identifier: "google-plus",
            scheme: "gplus:",
            fallbackURL: "https://plus.google.com/",
            appStoreID: "447119634"
        ),
        PTApplicationDescriptor(
            identifier: "google-sheets",
            scheme: "googlesheets:",
            fallbackURL: "http://www.google.com/sheets/about/",
            appStoreID: "842849113"
        ),
        PTApplicationDescriptor(
            identifier: "google-slides",
            scheme: "googleslides:",
            fallbackURL: "http://www.google.com/slides/about/",
            appStoreID: "879478102"
        ),
        PTApplicationDescriptor(
            identifier: "google-translate",
            scheme: "googletranslate:",
            fallbackURL: "https://translate.google.com/about/intl/en_ALL/index.html",
            appStoreID: "414706506"
        ),
        PTApplicationDescriptor(
            identifier: "groupe-me",
            scheme: "groupme:",
            fallbackURL: "https://groupme.com",
            appStoreID: "392796698"
        ),
        PTApplicationDescriptor(
            identifier: "heapo",
            scheme: "heap:",
            fallbackURL: "https://itunes.apple.com/us/app/heapo-clipboard-management-widget-copy-paste-clips/id921961118?mt=8",
            appStoreID: "921961118"
        ),
        PTApplicationDescriptor(
            identifier: "hoot-suite",
            scheme: "hootsuite:",
            fallbackURL: "https://hootsuite.com/products/mobile-apps/hootsuite-mobile-app",
            appStoreID: "341249709"
        ),
        PTApplicationDescriptor(
            identifier: "i-movie",
            scheme: "iMovie:",
            fallbackURL: "",
            appStoreID: "377298193"
        ),
        PTApplicationDescriptor(
            identifier: "ibooks",
            scheme: "itms-Books:",
            fallbackURL: "https://itunes.apple.com/us/app/ibooks/id364709193?mt=8",
            appStoreID: "364709193"
        ),
        PTApplicationDescriptor(
            identifier: "im-db",
            scheme: "imdb:",
            fallbackURL: "http://www.imdb.com/",
            appStoreID: "342792525"
        ),
        PTApplicationDescriptor(
            identifier: "inrix-traffic",
            scheme: "inrixtraffic:",
            fallbackURL: "http://inrix.com/inrix-traffic-app/",
            appStoreID: "324384027"
        ),
        PTApplicationDescriptor(
            identifier: "instagram",
            scheme: "instagram:",
            fallbackURL: "https://instagram.com/",
            appStoreID: "389801252"
        ),
        PTApplicationDescriptor(
            identifier: "instapaper",
            scheme: "instapaper:",
            fallbackURL: "https://www.instapaper.com/iphone",
            appStoreID: "288545208"
        ),
        PTApplicationDescriptor(
            identifier: "ishows",
            scheme: "ishows:",
            fallbackURL: "http://ishowsapp.com",
            appStoreID: "992387872"
        ),
        PTApplicationDescriptor(
            identifier: "itranslate",
            scheme: "itranslate:",
            fallbackURL: "http://itranslateapp.com/",
            appStoreID: "288113403"
        ),
        PTApplicationDescriptor(
            identifier: "itunes-u",
            scheme: "itms-itunesu:",
            fallbackURL: "https://itunes.apple.com/kw/app/itunes-u/id490217893?mt=8",
            appStoreID: "490217893"
        ),
        PTApplicationDescriptor(
            identifier: "kakao-talk",
            scheme: "kakaotalk:",
            fallbackURL: "http://www.kakao.com/talk",
            appStoreID: "362057947"
        ),
        PTApplicationDescriptor(
            identifier: "kayak",
            scheme: "kayak:",
            fallbackURL: "https://www.kayak.ae/",
            appStoreID: "305204535"
        ),
        PTApplicationDescriptor(
            identifier: "keeper",
            scheme: "keeper:",
            fallbackURL: "https://keepersecurity.com/",
            appStoreID: "287170072"
        ),
        PTApplicationDescriptor(
            identifier: "kik",
            scheme: "kik:",
            fallbackURL: "http://www.kik.com",
            appStoreID: "357218860"
        ),
        PTApplicationDescriptor(
            identifier: "last-pass",
            scheme: "lastpass:",
            fallbackURL: "https://lastpass.com",
            appStoreID: "324613447"
        ),
        PTApplicationDescriptor(
            identifier: "line",
            scheme: "line:",
            fallbackURL: "http://line.me/",
            appStoreID: "443904275"
        ),
        PTApplicationDescriptor(
            identifier: "linkedin",
            scheme: "linkedin:",
            fallbackURL: "http://www.linkedin.com/",
            appStoreID: "288429040"
        ),
        PTApplicationDescriptor(
            identifier: "mail",
            scheme: "mailto:",
            fallbackURL: "mailto:",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "marktplaats",
            scheme: "marktplaats:",
            fallbackURL: "http://www.marktplaats.nl",
            appStoreID: "373963365"
        ),
        PTApplicationDescriptor(
            identifier: "marvis",
            scheme: "marvis:",
            fallbackURL: "http://appaddy.wix.com/marvis",
            appStoreID: "971737469"
        ),
        PTApplicationDescriptor(
            identifier: "meerkat",
            scheme: "meerkat:",
            fallbackURL: "http://meerkatapp.co",
            appStoreID: "954105918"
        ),
        PTApplicationDescriptor(
            identifier: "messages",
            scheme: "sms:",
            fallbackURL: "sms:",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "mobile-mouse",
            scheme: "mobilemouse:",
            fallbackURL: "http://www.mobilemouse.com",
            appStoreID: "356395556"
        ),
        PTApplicationDescriptor(
            identifier: "mopico",
            scheme: "mopico:",
            fallbackURL: "http://mo-pi-co.com",
            appStoreID: "879992496"
        ),
        PTApplicationDescriptor(
            identifier: "moves",
            scheme: "moves:",
            fallbackURL: "https://www.moves-app.com",
            appStoreID: "509204969"
        ),
        PTApplicationDescriptor(
            identifier: "music",
            scheme: "music:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "my-fitness-pal",
            scheme: "mfp:",
            fallbackURL: "https://www.myfitnesspal.com",
            appStoreID: "341232718"
        ),
        PTApplicationDescriptor(
            identifier: "name-shark",
            scheme: "nameshark:",
            fallbackURL: "http://www.namesharkapp.com",
            appStoreID: "906531062"
        ),
        PTApplicationDescriptor(
            identifier: "netflix",
            scheme: "nflx:",
            fallbackURL: "https://www.netflix.com",
            appStoreID: "363590051"
        ),
        PTApplicationDescriptor(
            identifier: "notes",
            scheme: "mobilenotes:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "npo-radio",
            scheme: "nporadio1:",
            fallbackURL: "",
            appStoreID: "356566983"
        ),
        PTApplicationDescriptor(
            identifier: "nunl",
            scheme: "nunl:",
            fallbackURL: "http://www.nu.nl",
            appStoreID: "382059927"
        ),
        PTApplicationDescriptor(
            identifier: "ny-times",
            scheme: "nytimes:",
            fallbackURL: "http://www.nytimes.com/services/mobile/index.html",
            appStoreID: "284862083"
        ),
        PTApplicationDescriptor(
            identifier: "omt",
            scheme: "onemorething:",
            fallbackURL: "http://www.onemorething.nl",
            appStoreID: "483523981"
        ),
        PTApplicationDescriptor(
            identifier: "one-drive",
            scheme: "ms-onedrive:",
            fallbackURL: "https://onedrive.live.com/",
            appStoreID: "477537958"
        ),
        PTApplicationDescriptor(
            identifier: "one-password",
            scheme: "onepassword:",
            fallbackURL: "https://agilebits.com/onepassword",
            appStoreID: "568903335"
        ),
        PTApplicationDescriptor(
            identifier: "outlook",
            scheme: "ms-outlook:",
            fallbackURL: "http://www.outlook.com/",
            appStoreID: "951937596"
        ),
        PTApplicationDescriptor(
            identifier: "paypal",
            scheme: "paypal:",
            fallbackURL: "https://paypal.com/",
            appStoreID: "283646709"
        ),
        PTApplicationDescriptor(
            identifier: "periscope",
            scheme: "pscp:",
            fallbackURL: "https://www.periscope.tv",
            appStoreID: "972909677"
        ),
        PTApplicationDescriptor(
            identifier: "phone",
            scheme: "tel:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "photos",
            scheme: "photos-redirect:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "pic-collage",
            scheme: "mixiapp-piccollage:",
            fallbackURL: "http://pic-collage.com",
            appStoreID: "448639966"
        ),
        PTApplicationDescriptor(
            identifier: "pinterest",
            scheme: "pinterest:",
            fallbackURL: "https://www.pinterest.com/",
            appStoreID: "429047995"
        ),
        PTApplicationDescriptor(
            identifier: "pocket",
            scheme: "pocket:",
            fallbackURL: "https://getpocket.com/ios/?ep=1",
            appStoreID: "309601447"
        ),
        PTApplicationDescriptor(
            identifier: "podcasts",
            scheme: "podcasts:",
            fallbackURL: "https://itunes.apple.com/us/app/podcasts/id525463029?mt=8",
            appStoreID: "525463029"
        ),
        PTApplicationDescriptor(
            identifier: "quora",
            scheme: "Quora:",
            fallbackURL: "https://www.quora.com/",
            appStoreID: "456034437"
        ),
        PTApplicationDescriptor(
            identifier: "radium",
            scheme: "radium:",
            fallbackURL: "http://catpigstudios.com",
            appStoreID: "684034823"
        ),
        PTApplicationDescriptor(
            identifier: "reminders-app",
            scheme: "x-apple-reminder:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "remote",
            scheme: "remote:",
            fallbackURL: "",
            appStoreID: "284417350"
        ),
        PTApplicationDescriptor(
            identifier: "rijnmond",
            scheme: "rtvrijnmond:",
            fallbackURL: "http://www.rijnmond.nl",
            appStoreID: "421376740"
        ),
        PTApplicationDescriptor(
            identifier: "robo-form",
            scheme: "roboform:",
            fallbackURL: "http://www.roboform.com/for-iphone-ipad-ios",
            appStoreID: "331787573"
        ),
        PTApplicationDescriptor(
            identifier: "run-keeper",
            scheme: "RunKeeper:",
            fallbackURL: "https://runkeeper.com/index",
            appStoreID: "300235330"
        ),
        PTApplicationDescriptor(
            identifier: "scanner-pro",
            scheme: "spprint:",
            fallbackURL: "https://readdle.com/products/scannerpro/",
            appStoreID: "333710667"
        ),
        PTApplicationDescriptor(
            identifier: "simplenote",
            scheme: "simplenote:",
            fallbackURL: "http://simplenote.com",
            appStoreID: "289429962"
        ),
        PTApplicationDescriptor(
            identifier: "skitch",
            scheme: "skitch:",
            fallbackURL: "https://evernote.com/skitch/",
            appStoreID: "490505997"
        ),
        PTApplicationDescriptor(
            identifier: "skype",
            scheme: "Skype:",
            fallbackURL: "http://www.skype.com/",
            appStoreID: "304878510"
        ),
        PTApplicationDescriptor(
            identifier: "slack",
            scheme: "slack:",
            fallbackURL: "https://slack.com",
            appStoreID: "803453959"
        ),
        PTApplicationDescriptor(
            identifier: "snapchat",
            scheme: "snapchat:",
            fallbackURL: "https://www.snapchat.com",
            appStoreID: "447188370"
        ),
        PTApplicationDescriptor(
            identifier: "snapseed",
            scheme: "googlesnapseed:",
            fallbackURL: "https://support.google.com/snapseed/#topic=6155507",
            appStoreID: "439438619"
        ),
        PTApplicationDescriptor(
            identifier: "songpop2",
            scheme: "songpop:",
            fallbackURL: "https://www.songpop2.com",
            appStoreID: "975364678"
        ),
        PTApplicationDescriptor(
            identifier: "sonos",
            scheme: "sonos:",
            fallbackURL: "http://www.sonos.com/",
            appStoreID: "293523031"
        ),
        PTApplicationDescriptor(
            identifier: "soundflake",
            scheme: "soundflake:",
            fallbackURL: "http://soundflakeapp.com",
            appStoreID: "914459618"
        ),
        PTApplicationDescriptor(
            identifier: "spark",
            scheme: "readdle-spark:",
            fallbackURL: "https://readdle.com/products/spark",
            appStoreID: "997102246"
        ),
        PTApplicationDescriptor(
            identifier: "ssg2",
            scheme: "SSG2:",
            fallbackURL: "http://www.noodlecake.com/games/super-stickman-golf-2/",
            appStoreID: "585259203"
        ),
        PTApplicationDescriptor(
            identifier: "stitcher-radio",
            scheme: "stitcher:",
            fallbackURL: "http://www.stitcher.com",
            appStoreID: "288087905"
        ),
        PTApplicationDescriptor(
            identifier: "strava",
            scheme: "strava:",
            fallbackURL: "http://www.strava.com/mobile",
            appStoreID: "426826309"
        ),
        PTApplicationDescriptor(
            identifier: "subway-korea",
            scheme: "subwaykorea:",
            fallbackURL: "http://blog.malangstudio.com",
            appStoreID: "325924444"
        ),
        PTApplicationDescriptor(
            identifier: "sunrise-calendar",
            scheme: "sunrise:",
            fallbackURL: "https://calendar.sunrise.am",
            appStoreID: "599114150"
        ),
        PTApplicationDescriptor(
            identifier: "swarm",
            scheme: "swarm:",
            fallbackURL: "https://www.swarmapp.com",
            appStoreID: "870161082"
        ),
        PTApplicationDescriptor(
            identifier: "talabat",
            scheme: "talabat:",
            fallbackURL: "https://www.talabat.com",
            appStoreID: "451001072"
        ),
        PTApplicationDescriptor(
            identifier: "tango",
            scheme: "tango:",
            fallbackURL: "http://www.tango.me",
            appStoreID: "372513032"
        ),
        PTApplicationDescriptor(
            identifier: "ted",
            scheme: "ted:",
            fallbackURL: "https://www.ted.com",
            appStoreID: "376183339"
        ),
        PTApplicationDescriptor(
            identifier: "telegram",
            scheme: "tg:",
            fallbackURL: "https://t.me/",
            appStoreID: "686449807"
        ),
        PTApplicationDescriptor(
            identifier: "test-flight",
            scheme: "itms-beta:",
            fallbackURL: "",
            appStoreID: "899247664"
        ),
        PTApplicationDescriptor(
            identifier: "tinder",
            scheme: "tinder:",
            fallbackURL: "https://www.gotinder.com",
            appStoreID: "547702041"
        ),
        PTApplicationDescriptor(
            identifier: "trello",
            scheme: "trello:",
            fallbackURL: "https://trello.com/",
            appStoreID: "461504587"
        ),
        PTApplicationDescriptor(
            identifier: "tubex",
            scheme: "tubex:",
            fallbackURL: "https://www.facebook.com/Tubex-744986562245828/",
            appStoreID: "939906112"
        ),
        PTApplicationDescriptor(
            identifier: "tumblr",
            scheme: "tumblr:",
            fallbackURL: "https://www.tumblr.com",
            appStoreID: "305343404"
        ),
        PTApplicationDescriptor(
            identifier: "tweetbot",
            scheme: "tweetbot:",
            fallbackURL: "http://tapbots.com/tweetbot/",
            appStoreID: "722294701"
        ),
        PTApplicationDescriptor(
            identifier: "twitter",
            scheme: "twitter:",
            fallbackURL: "https://twitter.com/",
            appStoreID: "333903271"
        ),
        PTApplicationDescriptor(
            identifier: "twitterrific",
            scheme: "twitterrific:",
            fallbackURL: "http://twitterrific.com/ios",
            appStoreID: "580311103"
        ),
        PTApplicationDescriptor(
            identifier: "uber",
            scheme: "uber:",
            fallbackURL: "https://www.uber.com",
            appStoreID: "368677368"
        ),
        PTApplicationDescriptor(
            identifier: "unread",
            scheme: "unread:",
            fallbackURL: "http://supertop.co/unread/",
            appStoreID: "911364254"
        ),
        PTApplicationDescriptor(
            identifier: "ustream",
            scheme: "ustream:",
            fallbackURL: "https://www.ustream.tv/platform/watch-everywhere",
            appStoreID: "301520250"
        ),
        PTApplicationDescriptor(
            identifier: "viber",
            scheme: "viber:",
            fallbackURL: "http://www.viber.com/",
            appStoreID: "382617920"
        ),
        PTApplicationDescriptor(
            identifier: "videos",
            scheme: "videos:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "views",
            scheme: "views:",
            fallbackURL: "http://www.saikambampati.com/views",
            appStoreID: "1322754821"
        ),
        PTApplicationDescriptor(
            identifier: "vimeo",
            scheme: "vimeo:",
            fallbackURL: "https://vimeo.com/everywhere",
            appStoreID: "425194759"
        ),
        PTApplicationDescriptor(
            identifier: "vine",
            scheme: "vine:",
            fallbackURL: "https://vine.co",
            appStoreID: "592447445"
        ),
        PTApplicationDescriptor(
            identifier: "vip-access",
            scheme: "vipsymantec:",
            fallbackURL: "https://m.vip.symantec.com",
            appStoreID: "307658513"
        ),
        PTApplicationDescriptor(
            identifier: "vox",
            scheme: "com.coppertino.vox:",
            fallbackURL: "http://coppertino.com/vox/iphone",
            appStoreID: "916215494"
        ),
        PTApplicationDescriptor(
            identifier: "voxer",
            scheme: "voxer:",
            fallbackURL: "http://www.voxer.com",
            appStoreID: "377304531"
        ),
        PTApplicationDescriptor(
            identifier: "vsco",
            scheme: "vsco:",
            fallbackURL: "http://vsco.co/store/app",
            appStoreID: "588013838"
        ),
        PTApplicationDescriptor(
            identifier: "wallet",
            scheme: "shoebox:",
            fallbackURL: "",
            appStoreID: nil
        ),
        PTApplicationDescriptor(
            identifier: "waze",
            scheme: "waze:",
            fallbackURL: "https://www.waze.com",
            appStoreID: "323229106"
        ),
        PTApplicationDescriptor(
            identifier: "we-chat",
            scheme: "weixin:",
            fallbackURL: "https://weixin.qq.com/",
            appStoreID: "414478124"
        ),
        PTApplicationDescriptor(
            identifier: "weibo",
            scheme: "weibo:",
            fallbackURL: "http://weibo.com/login.php",
            appStoreID: "350962117"
        ),
        PTApplicationDescriptor(
            identifier: "whats-app",
            scheme: "whatsapp:",
            fallbackURL: "https://www.whatsapp.com/",
            appStoreID: "310633997"
        ),
        PTApplicationDescriptor(
            identifier: "whyd",
            scheme: "whyd:",
            fallbackURL: "https://whyd.com",
            appStoreID: "874380201"
        ),
        PTApplicationDescriptor(
            identifier: "wikipanion",
            scheme: "wikipanion:",
            fallbackURL: "http://www.wikipanion.com/download.html?iphone",
            appStoreID: "288349436"
        ),
        PTApplicationDescriptor(
            identifier: "word-press",
            scheme: "wordpress:",
            fallbackURL: "https://apps.wordpress.org",
            appStoreID: "335703880"
        ),
        PTApplicationDescriptor(
            identifier: "workflow",
            scheme: "workflow:",
            fallbackURL: "https://workflow.is",
            appStoreID: "915249334"
        ),
        PTApplicationDescriptor(
            identifier: "yahoo-weather",
            scheme: "yweather:",
            fallbackURL: "https://mobile.yahoo.com/weather/",
            appStoreID: "628677149"
        ),
        PTApplicationDescriptor(
            identifier: "yammer",
            scheme: "yammer:",
            fallbackURL: "https://products.office.com/en-us/yammer/yammer-mobile-app",
            appStoreID: "289559439"
        ),
        PTApplicationDescriptor(
            identifier: "yelp",
            scheme: "yelp4:",
            fallbackURL: "https://m.yelp.com/",
            appStoreID: "284910350"
        ),
        PTApplicationDescriptor(
            identifier: "you-tube",
            scheme: "youtube:",
            fallbackURL: "https://www.youtube.com/",
            appStoreID: "544007664"
        ),
    ]

    static func descriptor(identifier: String) -> PTApplicationDescriptor? {
        all.first { $0.identifier == identifier }
    }
}
