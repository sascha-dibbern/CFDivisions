Name: <% $zilla->name %>
Version: <% (my $v = $zilla->version) =~ s/^v//; $v %>
Release: 1

Summary: <% $zilla->abstract %>
License: <% $zilla->license->name %>
Group: Applications/CPAN
BuildArch: noarch
URL: <% $zilla->license->url %>
Vendor: <% $zilla->license->holder %>
Source: <% $archive %>

BuildRoot: %{_tmppath}/%{name}-%{version}-BUILD
BuildRequires: perl
Requires: perl

%description
<% $zilla->abstract %>

%prep
%setup -q

%build
CFMODULES=${CFMODULES:-'/var/cfengine/modules'}
PERL_MM_OPT="INSTALLDIRS=site INSTALLSITEARCH=${INSTALLSITEARCH:-'${CFMODULES}/lib64/perl5'} INSTALLSITEBIN=${INSTALLSITEBIN:-'${CFMODULES}/bin'} INSTALLSITELIB=${INSTALLSITELIB:-'${CFMODULES}/perl5'} INSTALLSITEMAN1DIR=${INSTALLSITEMAN1DIR:-'/usr/local/share/man/man1'} INSTALLSITEMAN3DIR=${INSTALLSITEMAN3DIR:-'/usr/local/share/man/man3'} INSTALLSITESCRIPT=${INSTALLSITESCRIPT:-'${CFMODULES}'}"
env | sort
perl Makefile.PL
make test
    
%install
if [ "$RPMBUILDLOG" = "" ]; then
    RPMBUILDLOG=/dev/null
fi
if [ "%{buildroot}" != "/" ] ; then
    rm -rf %{buildroot}
fi
echo "buildroot: %{buildroot}" >>$RPMBUILDLOG
env | sort >>$RPMBUILDLOG
make install DESTDIR=%{buildroot} >>$RPMBUILDLOG
echo "filelist: %{_tmppath}/filelist" >>$RPMBUILDLOG
#find %{buildroot} | sed -e 's#%{buildroot}##' | perl -lne 'print if ! (($_ eq "/usr/lib64") or ($_ eq "/var/cfengine/modules"))' > %{_tmppath}/filelist
find %{buildroot} | sed -e 's#%{buildroot}##' | perl -lne 'print if ! (-d $_)' > %{_tmppath}/filelist
cat %{_tmppath}/filelist >>$RPMBUILDLOG

%clean
if [ "%{buildroot}" != "/" ] ; then
    rm -rf %{buildroot}
fi

%post

%preun

%files -f %{_tmppath}/filelist
%defattr(-,root,root)
%doc

%changelog
