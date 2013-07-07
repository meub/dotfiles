###############################################################################
# Meub's Bash Profile                                                         #
# Required: s3cmd, ngrep, git                                                 #
# Recommended: wget, lynx, node, webkit2png, imagemagick, rename, tree        #
###############################################################################

#Export Path - includes sublime text symlink - http://tinyurl.com/lc2ho3y
export PATH=$PATH:/usr/local/bin

# Make vim the default editor
export EDITOR="vim"

###############################################################################
# Aliases                                                                     #
###############################################################################

# Easier navigation: .., ..., ...., ....., ~ and -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~" # `cd` is probably faster to type though
alias -- -="cd -"

# Shortcuts
alias d="cd /Dropbox"
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias p="cd /Dropbox/Dev/Projects"

# List all Directories
alias lsd='ls -l ${colorflag} | grep "^d"'

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Enable aliases to be sudo’ed
alias sudo='sudo '

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)\|[a-fA-F0-9:]\+\)' | sed -e 's/inet6* //'"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en0' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en0 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Flush Directory Service cache
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"

###############################################################################
# Functions                                                                   #
###############################################################################

# Custom search
function search() {
	if [ "$2" ]
	then
	    if [ "$1" == "-" ]
	    then
	        #echo "----Searching all files----"
	        grep -ir "$2" .
	    else
	        #echo "----Searching files which match file name----"
	        find . -iname "$1" -exec grep -i "$2" {} ";"
	    fi
	else
	    if [ "$1" ]
	    then
	        #echo "----Finding files by name----"
	        find . -iname "$1"
	    else
	        echo "------- Searches the current directory -------"
	        echo ""
	        echo "Search by file name only: "
	        echo "   search *.html"
	        echo ""
	        echo "Search inside files which match file name: "
	        echo "   search *.html \"<meta\""
	        echo ""
	        echo "Search inside all files: "
	        echo "   search - \"<meta\""
	    fi
	fi
}


# Upload image to images bucket
function s3image() {
	s3cmd put --acl-public --guess-mime-type "$@" s3://images.alexmeub.com/"$@"
}


# Upload image to images bucket
function s3image() {
	s3cmd put --acl-public --guess-mime-type "$@" s3://images.alexmeub.com/"$@"
}

# Make bucket public
function s3public(){
	s3cmd setacl --acl-public --recursive s3://"$@"
}

# Create a new directory and enter it
function mkd() {
	mkdir -p "$@" && cd "$@"
}

# Determine size of a file or total size of a directory
function fs() {
	if du -b /dev/null > /dev/null 2>&1; then
		local arg=-sbh
	else
		local arg=-sh
	fi
	if [[ -n "$@" ]]; then
		du $arg -- "$@"
	else
		du $arg .[^.]* *
	fi
}

# Create a data URL from a file
function dataurl() {
	local mimeType=$(file -b --mime-type "$1")
	if [[ $mimeType == text/* ]]; then
		mimeType="${mimeType};charset=utf-8"
	fi
	echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
	local port="${1:-8000}"
	sleep 1 && open "http://localhost:${port}/" &
	# Set the default Content-Type to `text/plain` instead of `application/octet-stream`
	# And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
	python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# Compare original and gzipped file size
function gz() {
	local origsize=$(wc -c < "$1")
	local gzipsize=$(gzip -c "$1" | wc -c)
	local ratio=$(echo "$gzipsize * 100/ $origsize" | bc -l)
	printf "orig: %d bytes\n" "$origsize"
	printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio"
}

# Test if HTTP compression (RFC 2616 + SDCH) is enabled for a given URL.
# Send a fake UA string for sites that sniff it instead of using the Accept-Encoding header. (Looking at you, ajax.googleapis.com!)
function httpcompression() {
	encoding="$(curl -LIs -H 'User-Agent: Mozilla/5 Gecko' -H 'Accept-Encoding: gzip,deflate,compress,sdch' "$1" | grep '^Content-Encoding:')" && echo "$1 is encoded using ${encoding#* }" || echo "$1 is not using any encoding"
}