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
Requires: cfengine >= 3.2

%description
<% $zilla->abstract %>

%prep
%setup -q

%build
PERL_MM_OPT="INSTALLDIRS=site INSTALLSITEARCH='/usr/local/lib64/perl5' INSTALLSITEBIN='/usr/local/bin' INSTALLSITELIB='/usr/local/share/perl5' INSTALLSITEMAN1DIR=/usr/local/share/man/man1 INSTALLSITEMAN3DIR=/usr/local/share/man/man3 INSTALLSITESCRIPT='/usr/local/bin'"
perl Makefile.PL
make test
    
%install
if [ "%{buildroot}" != "/" ] ; then
    rm -rf %{buildroot}
fi
echo "buildroot: %{buildroot}"
env | sort
make install DESTDIR=%{buildroot}
echo "filelist: %{_tmppath}/filelist"
find %{buildroot} | sed -e 's#%{buildroot}##' > %{_tmppath}/filelist

%clean
if [ "%{buildroot}" != "/" ] ; then
    rm -rf %{buildroot}
fi

%post
cp /usr/local/bin/cfdivisions /var/cfengine/modules/cfdivisions

%preun
rm /var/cfengine/modules/cfdivisions

%files -f %{_tmppath}/filelist
%defattr(-,root,root)
%doc

%changelog
