%{!?ruby_sitelib: %global ruby_sitelib %(ruby -rrbconfig -e 'puts Config::CONFIG["sitelibdir"] ')}
%define rel 0.1

Summary: Configuration store
Name: configuration-store
Version: 0.1.0
Release: %{rel}%{?dist}
Group: Applications/System
License: ASL 2.0
URL: http://git.fedorahosted.org/git/grid/configuration-store.git
Source0: %{name}-%{version}-%{rel}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: ruby(abi) = 1.8
Requires: ruby
Requires: ruby-spqr
Requires: ruby-rhubarb
Requires: ruby-qmf
Requires: ruby-config-store
BuildArch: noarch

%description
Configuration store.

%package utils
Summary: Configuration store utilities
Group: Applications/System
Requires: ruby(abi) = 1.8
Requires: ruby
Requires: ruby-qmf
Requires: ruby-config-store

%description utils
Utilities for interacting with the configration store

%package -n ruby-config-store
Summary: Functions used by the qmf configuration store
Group: Applications/System
Requires: ruby(abi) = 1.8
Requires: ruby
Requires: ruby-qmf
BuildRequires: ruby

%description -n ruby-config-store
Functions used by various parts of the qmf configuration store

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{ruby_sitelib}/mrg/grid/config/dbmigrate
mkdir -p %{buildroot}/%{_bindir}
cp -f bin/store-dump.rb %{buildroot}/%{_bindir}
cp -f bin/store-load.rb %{buildroot}/%{_bindir}
cp -f bin/store-agent.rb %{buildroot}/%{_bindir}
cp -f lib/mrg/grid/*.rb %{buildroot}/%{ruby_sitelib}/mrg/grid
cp -f lib/mrg/grid/config/*.rb %{buildroot}/%{ruby_sitelib}/mrg/grid/config
cp -f lib/mrg/grid/config/dbmigrate/*.rb %{buildroot}/%{ruby_sitelib}/mrg/grid/config/dbmigrate

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%doc LICENSE README.rdoc TODO VERSION
%defattr(0755,root,root,-)
%{_bindir}/store-agent.rb

%files utils
%defattr(-, root, root, -)
%doc LICENSE
%defattr(0755,root,root,-)
%{_bindir}/store-load.rb
%{_bindir}/store-dump.rb

%files -n ruby-config-store
%defattr(-, root, root, -)
%{ruby_sitelib}/mrg/grid/config.rb
%{ruby_sitelib}/mrg/grid/config-client.rb
%{ruby_sitelib}/mrg/grid/config-proxies.rb
%{ruby_sitelib}/mrg/grid/config/ArcLabel.rb
%{ruby_sitelib}/mrg/grid/config/ArcUtils.rb
%{ruby_sitelib}/mrg/grid/config/Configuration.rb
%{ruby_sitelib}/mrg/grid/config/Feature.rb
%{ruby_sitelib}/mrg/grid/config/Group.rb
%{ruby_sitelib}/mrg/grid/config/Node.rb
%{ruby_sitelib}/mrg/grid/config/Parameter.rb
%{ruby_sitelib}/mrg/grid/config/QmfUtils.rb
%{ruby_sitelib}/mrg/grid/config/Snapshot.rb
%{ruby_sitelib}/mrg/grid/config/Store.rb
%{ruby_sitelib}/mrg/grid/config/Subsystem.rb
%{ruby_sitelib}/mrg/grid/config/dbmeta.rb
%{ruby_sitelib}/mrg/grid/config/dbmigrate/1.rb

%changelog
* Wed Jan 27 2010 root <root@fedora12-test> - 0.1.0-1
- Initial package
