#!/bin/bash
apt-get update
# get the new certs
apt-get -y install wget
wget -O /etc/ssl/certs/ldap-eng-vmware.pem
http://engweb.eng.vmware.com/sipublic/ldap/ldap-eng-vmware.pem
# setup packages
apt-get -y install ldap-auth-client autofs-ldap nslcd libnss-ldapd
apt-get -y install ldap-utils

cat <<-__debconf_EOF__ | debconf-communicate
    set ldap-auth-config/bindpw (password omitted)
    set ldap-auth-config/bindpw (password omitted)
    set ldap-auth-config/rootbindpw (password omitted)
    set ldap-auth-config/binddn dc=vmware,dc=com
    set ldap-auth-config/dbrootlogin false
    set ldap-auth-config/rootbinddn cn=manager,dc=vmware,dc=com
    set ldap-auth-config/pam_password md5
    set ldap-auth-config/move-to-debconf true
    set ldap-auth-config/ldapns/ldap-server ldaps://ldaps.eng.vmware.com:636/
    set ldap-auth-config/ldapns/base-dn dc=vmware,dc=com
    set ldap-auth-config/override true
    set ldap-auth-config/ldapns/ldap_version 3
    set ldap-auth-config/dblogin false
    set nslcd/ldap-bindpw (password omitted)
    set nslcd/ldap-starttls false
    set nslcd/ldap-base dc=vmware,dc=com
    set nslcd/ldap-reqcert
    set nslcd/ldap-uris ldaps://ldaps.eng.vmware.com:636/
    set nslcd/ldap-binddn
__debconf_EOF__

apt-get -y install ldap-auth-config

echo "working on ldap-conf "

if [ -e  /etc/ldap.conf ]
then
    echo "Updating /etc/ldap.conf"
    sed -i /etc/ldap.conf \
    -e 's/^#ldap_version 3/ldap_version 3/i' \
    -e 's/^base /#base /i' \
    -e 's/^host /#host /i' \
    -e 's/^port /#port /i' \
    -e 's/^uri /#uri /i' \
    -e 's/^ssl /#ssl /i' \
    -e 's/^tls /#tls /i' \
    -e 's/^tls_reqcert /#tls_reqcert /i' \
    -e 's/^tls_cacert /#tls_cacert /i' \
    -e 's/^bind_policy /#bind_policy /i'

    cat <<-__ldapconf_EOF__ >> /etc/ldap.conf
URI ldaps://ldaps.eng.vmware.com:636/
BASE            dc=vmware,dc=com
SSL             off
TLS             hard
TLS_REQCERT     demand
TLS_CACERT      /etc/ssl/certs/ldap-eng-vmware.pem
BIND_POLICY     soft
pam_password_prohibit_message Please use pa-psynch2.vmware.com to change your
password
__ldapconf_EOF__
fi

if [ -e  /etc/ldap/ldap.conf ]
then
    echo "Updating /etc/ldap/ldap.conf"
    sed -i /etc/ldap/ldap.conf \
-e 's/^#ldap_version 3/ldap_version 3/i' \
-e 's/^base /#base /i' \
-e 's/^host /#host /i' \
-e 's/^port /#port /i' \
-e 's/^uri /#uri /i' \
-e 's/^ssl /#ssl /i' \
-e 's/^tls /#tls /i' \
-e 's/^tls_reqcert /#tls_reqcert /i' \
-e 's/^tls_cacert /#tls_cacert /i' \
-e 's/^bind_policy /#bind_policy /i'

    cat <<-__ldapconf2_EOF__ >> /etc/ldap/ldap.conf
URI ldaps://ldaps.eng.vmware.com:636/
BASE            dc=vmware,dc=com
SSL             off
TLS             hard
TLS_REQCERT     demand
TLS_CACERT      /etc/ssl/certs/ldap-eng-vmware.pem
BIND_POLICY     soft
pam_password_prohibit_message Please use https://pa-psynch2.vmware.com/ to
change your password.
__ldapconf2_EOF__
fi

    if [ -e /etc/nslcd.conf ]
    then
        echo " "
        echo "Updating nslcd.conf"
        sed -i /etc/nslcd.conf \
            -e 's/^uri/# uri/i' \
            -e 's/^base/# base/i' \
            -e 's/^ssl/# ssl/i' \
            -e 's/^tls/# tls/i' \
            -e 's/^#ldap_version 3/ldap_version 3/i'

        cat <<-__nslcd_EOF__ >>/etc/nslcd.conf
URI ldaps://ldaps.eng.vmware.com:636/
BASE            dc=vmware,dc=com
SSL             no
TLS_REQCERT     demand
TLS_CACERTFILE  /etc/ssl/certs/ldap-eng-vmware.pem
__nslcd_EOF__

    fi

    if [ -e /etc/nscd.conf ]
    then
        echo " "
        echo "Updating nscd.conf"
        sed -r -i /etc/nscd.conf \
            -e '/paranoia/s/no$/yes/' \
            -e '/restart-interval[^<>]+$/s/^#//' \
            -e '/restart-interval/s/3600$/172800/' \
            -e '/enable-cache.*passwd/s/no$/yes/' \
            -e '/enable-cache.*group/s/no$/yes/' \
            -e '/enable-cache.*hosts/s/yes$/no/' \
            -e '/enable-cache.*services/s/yes$/no/' \
            -e '/persistent/s/yes$/no/'
    fi

    if [ -e /etc/default/autofs ]
    then
        echo "Updating /etc/default/autofs"
        sed -i /etc/default/autofs \
            -e 's/^MAP_OBJECT_CLASS/#MAP_OBJECT_CLASS/i' \
            -e 's/^ENTRY_OBJECT_CLASS/#ENTRY_OBJECT_CLASS/i' \
            -e 's/^MAP_ATTRIBUTE/#MAP_ATTRIBUTE/i' \
            -e 's/^ENTRY_ATTRIBUTE/#ENTRY_ATTRIBUTE/i' \
            -e 's/^VALUE_ATTRIBUTE/#VALUE_ATTRIBUTE/i' \
            -e 's/^LDAP_URI/#LDAP_URI/i' \
            -e 's/^SEARCH_BASE/#SEARCH_BASE/i'

        cat <<-__autofs_EOF__ >>/etc/default/autofs
MAP_OBJECT_CLASS="automountMap"
ENTRY_OBJECT_CLASS="automount"
MAP_ATTRIBUTE="ou"
ENTRY_ATTRIBUTE="cn"
VALUE_ATTRIBUTE="automountInformation"
LDAP_URI="ldaps://ldaps.eng.vmware.com:636/"
SEARCH_BASE="dc=vmware,dc=com"
__autofs_EOF__
    fi

    if [ -e /etc/nsswitch.conf ]
    then
           echo " "
           echo "Ensuring automout and netgroup are defined in /etc/nsswich.conf"
           grep -r -q '^space:*netgroup:' /etc/nsswitch.conf 2>/dev/null || sed -i /etc/nsswitch.conf -e '$anetgroup: \n'
           grep -r -q '^space:*automount:' /etc/nsswitch.conf 2>/dev/null || sed -i /etc/nsswitch.conf -e '$aautomount: \n'
           sed -r -i /etc/nsswitch.conf \
                -e 's/netgroup:space:*.*/netgroup: ldap/' \
                -e 's/automount:space:*.*/automount: ldap/'
    fi

auth-client-config -t nss -p ldap_example
service nis stop
update-rc.d nis disable

service autofs stop
service nscd stop
service nslcd restart
service nscd start
service autofs start
