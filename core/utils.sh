#!/binbash

cwd="$(echo "$(pwd)")"
source "$cwd/styles/styles.sh"

# SCM available
# Take note: lower case names separated by ", "
AVAILABLE_SCM='github bucket gitlab'

###################################################################################################
###################################################################################################
#                                                    	                                     	  #
# Necessary functions                                                                             #
#                                                    	                                     	  #
###################################################################################################
###################################################################################################

installPackage(){
	local repository=$1
	local package=$2
	local is_installed="$(eval "echo \"$3\"")"
	local install_command=$4
	
	if [ $is_installed -eq 1 ];
	then
	  echo -e "$repository package ${BWhite}\"$package\"${Clear} is ${BGreen}installed${Clear}!"
	
	else
	  eval "$install_command"
	  
	  local msg_1="$repository package ${BWhite}\"$package\"${Clear} was not installed."
	  local msg_2="It is ${BGreen}installed${Clear} now!"
	  echo -e "$msg_1 $msg_2"
	fi
}

installPackages () {
	local repository="$1";
	local packages="$2";
	local is_installed="$3";
	local install_command="$4";

	for package in ${packages[@]}
	do
		full_is_installed="$(sed "s/package_name/$package/g" <<< "$is_installed")"
		full_install_command="$(sed "s/package_name/$package/g" <<< "$install_command")"
		
		installPackage "$repository" "$package" "$full_is_installed" "$full_install_command"
	done
}

# Repository apt
manageAptPackages () {
	local pkg_bundle_1='git python3-dev python3-pip python3-venv python3-apt'
	local pkg_bundle_2='virtualenv ipe xclip google-chrome-stable texlive-xetex'
	local pkg_bundle_3='texlive-fonts-recommended texlive-plain-generic npm chromium'
	local pkg_bundle_4='apt-transport-https curl'

	local packages="$pkg_bundle_1 $pkg_bundle_2 $pkg_bundle_3 $pkg_bundle_4"

	local param="'$(echo '${Status}')'"
	local head='$(dpkg-query -W -f='
	local tail=' package_name | grep -c "ok installed")'

	local is_installed="$head$param$tail"
	local install_cmd='apt install --upgrade package_name -y'

	installPackages 'apt' "$packages" "$is_installed" "$install_cmd"
}

# Repository snap
manageSnapPackages () {
	local packages="slack sublime-text gimp"

	local is_installed='$(("$(snap list | grep -c package_name)" > "0"))'
	local install_cmd='snap install package_name --classic'

	installPackages 'apt' "$packages" "$is_installed" "$install_cmd" 
}

# Repository Pip
managePipPackages () {
	# Repository pip
	local pkg_bundle_1='numpy pandas matplotlib scipy scikit-learn'
	local pkg_bundle_2='notebook pip-review pip-conflict-checker'
	local pkg_bundle_3='nbconvert[webpdf]'
	
	local packages="$pkg_bundle_1 $pkg_bundle_2 $pkg_bundle_3"

	local is_installed='$(("$(pip freeze | grep -c package_name)" > "0"))'
	local install_cmd='pip install package_name'

	installPackages 'apt' "$packages" "$is_installed" "$install_cmd" 	
}

# Install useful utils from different package repositories
managePackages() {	
	manageAptPackages
	echo 
	manageAptPackages
	echo
	managePipPackages
	echo
}

# Update, upgrade and fix packages
manageRepository () {
	local head="Repository ${BBlue}$1${Clear}:" 

	wrapHeaderFooter "`echo -e $head` Update and upgrade current packages." "$2"
	wrapHeaderFooter "`echo -e $head` List and/or fix current packages." "$3"
	wrapHeaderFooter "`echo -e $head` Remove unnecessary packages." "$4"
}

removeDuplicates () {
	chmod a+x 'aptsources-cleanup.pyz'
	./aptsources-cleanup.pyz
}

manageDuplicates () {
	wrapHeaderFooter "Remove package duplicates" "removeDuplicates"
}

generateSSHKey () {
	declare file_path="/$(whoami)/.ssh/$1_$2"
	declare full_file_path="$file_path.pub"
	
	declare file_folder=$(whoami)
	declare file_name=$1
	
	# Generate ssh key
	ssh-keygen -t $2 -C "$(getInfo 'e-mail')"
	
	# Agent
	eval "$(ssh-agent -s)"

	# Agent
	ssh-add $file_path

	xclip -sel clip < $full_file_path
}

testSSHConnection () {
	declare SCM_name="$1"
	declare SCM_host=''
	declare SSHConnection_approval_phrase=''

	if [[ $SCM_name == "github" ]]; then
	  SCM_host='github.com'
	  SSHConnection_approval_phrase='You''ve successfully authenticated'	  

	elif [[ $SCM_name=="bitbucket" ]]; then
	  SCM_host='bitbucket.org'
	  SSHConnection_approval_phrase='You can use git to connect to Bitbucket.'

	else
	  echo -e "SCM $1 not supported"
	  exit
	fi

	local ssh_msg="${BGreen}$(echo -e "$(ssh -q "git@$SCM_host")")${Clear}"
	if [ $(echo -e $ssh_msg | grep -c "$SSHConnection_approval_phrase" | wc -l) -eq 1 ]; then
	  echo -e $ssh_msg

	else
	  declare file_path="/$(whoami)/.ssh/$2_$3"
	  declare full_file_path="$file_path.pub"

	  echo -e "${BRed}Your SSH key is not configured properly.${Clear}"
	  echo -e "${BRed}Either setup your SCM tool with the content of file $full_file_path${Clear}" 
	  echo -e "${BRed}or ask your supervisor to do it.${Clear}"
	fi
}

requestGitSCM () {
	PS3="Enter the number of Source Code Management (SCM) toolkit: "
	select SCM in ${AVAILABLE_SCM[@]}; do
		case $SCM in
		    github)
		      echo -e $SCM
		      break
		      ;;
		    bitbucket)
		      echo -e $SCM
		      break
		      ;;
		    gitlab)
		      echo -e $SCM
		      break
		      ;;
		    quit)
			  echo -e 'quit'
		      break
		      ;;
		    *)
		      echo -e "${BRed}Invalid option $REPLY.$Clear" 
		      echo -e "${BRed}Available options are [$AVAILABLE_SCM, quit]${Clear}"
		      ;;
		  esac
	done
}

cloneGitRepository () {
	local repo_host=''
	
	if [[ "$1"="bitbucket" ]]; then
		repo_host='bitbucket.org'

	elif [[ "$1"="github" ]]; then
		repo_host='github.com'

	elif [[ "$1"="gitlab" ]]; then
		repo_host='gitlab.com'
	fi

	if [[ "$repo_host"='' ]]; then
		echo -e "${BRed}SCM $1 not currently supported!${Clear}"
		exit 0;
	fi

	git clone "git@$repo_host:$2/$3.git"
	exit 1;
}

requestGitInfoAndCloneGitRepository () {
	declare SCM_name=""
	declare organization_name=""
	declare repository_name=""

	SCM_name="$(getInfo 'SCM [github/bitbucket]')"
	organization_name="$(getInfo 'organization name ($organizationname/$repositoryname)')"
	repository_name="$(getInfo 'repository name ($organizationname/$repositoryname)')"
	
	cloneGitRepository $SCM_name $organization_name $repository_name
}

cloneGitRepositories () {
	local task='clone one more repository'

	while [ true ];
	do
		requestGitInfoAndCloneGitRepository
		
		local answer="$(echo -e "$(requestApproval "$task")")"

		if [ "$answer" == "y" ]; then 
			continue;
		elif [ "$answer" == "n" ] || [ "$answer" == "q" ] ; then 
			break;
		fi
	done
}

configGlobalGitUsername () {
	git config --global user.name "$1"
}

configGlobalGitEMail () {
	git config --global user.email "$1"
}