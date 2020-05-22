Red[]

.: context [

;api-key: make map! either exists? %api-key.red [load %api-key.red][copy []]

server-proto: context [
	base-url:
	api-key:
	cache:		none
	latest:		%latest
	base:		['base value]
	symbols:	['symbols join-with value comma]
	check:		func [value][value]
]

#TODO "move servers to block/map"

exchangeratesapi.io: make server-proto [
	base-url:	https://api.exchangeratesapi.io/
	cache:		%rates-exraa.red
]

fixer.io: make server-proto [
	base-url:	http://data.fixer.io/api/
	cache:		%rates-fixer.red
	latest:		[%latest?access_key= api-key]
	check:		func [value][
		unless value/success [
			do make error! value/error/type
		]
		value
	]
]

openexchangerates.org: make server-proto [
	base-url:	https://openexchangerates.org/api/
	cache:		%rates-opexa.red
	latest:		[%latest.json?app_id= api-key]
	check:		func [value][
		if value/error [
			do make error! value/description
		]
		value
	]
]

rate-data: none

convert-rates: func [
	currency	[any-word!]
	rates		[map!]
	/local out rate cur val
][
	out: make map! []
	rate: rates/:currency
	foreach [cur val] rates [
		out/:cur: rate / rates/:cur
	]
	out
]

set 'clear-rates-cache func [][
	foreach [server file] cache [delete file]
]

set 'make-rates-table func [
	rates	[map!]
;	/local out cur val
][
	out: copy []
	foreach [cur val] rates [
		repend out [
			to set-word! cur convert-rates cur rates
		]
	]
	out
]

set 'load-api-keys func [
	/keys
][
	if exists? keys: %api-key.red [
		foreach [server key] load keys [
			print [mold server mold key]
			server: get in self to word! server
			server/api-key: key
		]
	]
]

construct-url: func [
	base [url!]
	data [map!]
][
	base: copy base
	append base either find base #"?" [#"&"][#"?"]
	foreach [key value] data [
		repend base [key #"=" value #"&"]
	]
	take/last base
	base
]

join-with: func [
	series	[block!]
	char	[char!]
][
	collect/into [
		until [
			keep first series
			keep char
			series: next series
			tail? next series
		]
		keep last series
	] copy ""
]

value: none

construct-url: func [
	server [object!]
	words [block!]
	/local link word val
][
	link: copy [server/base-url]
	link: rejoin append link server/latest
	append link either find link #"?" [#"&"][#"?"]
	foreach [word val] words [
		if get word [
			value: get val
			append link rejoin [
				server/:word/1
				#"="
				do bind next server/:word self
				#"&"
			]
		]
	]
	take/last link
	link
]

set 'get-rates func [
	"Download rates for server's base currency"
	/from
		server	[word!]
	/force	"Force download, do not use cache"
	/base
		base-cur	"Use different base currency"
	/symbols
		symb-cur [block!]	"Download rates for these currencies only"
	/local link
][
	server: any [server 'exchangeratesapi.io]
	server: get bind server self
; -- caching
	all [
		exists? server/cache
		not force
		return load server/cache
	]
; -- construct request
	link: construct-url server [base base-cur symbols symb-cur]
; -- load required rates
	data: server/check load-json read link
	data/base: to word! data/base
	save server/cache data
	data
]

; -- end of context

load-api-keys

]
