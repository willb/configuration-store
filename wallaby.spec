%{!?ruby_sitelib: %global ruby_sitelib %(ruby -rrbconfig -e 'puts Config::CONFIG["sitelibdir"] ')}
%define rel 0.1

Summary: Configuration store via QMF
Name: wallaby
Version: 0.1.0
Release: %{rel}%{?dist}
Group: Applications/System
License: ASL 2.0
URL: http://git.fedorahosted.org/git/grid/wallaby.git
Source0: %{name}-%{version}-%{rel}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: ruby(abi) = 1.8
Requires: ruby
Requires: ruby-spqr
Requires: ruby-rhubarb
Requires: ruby-qmf
Requires: ruby-wallaby
BuildArch: noarch

%description
A QMF accessible configuration store.

%package utils
Summary: Configuration store utilities
Group: Applications/System
Requires: ruby(abi) = 1.8
Requires: ruby
Requires: ruby-qmf
Requires: ruby-wallaby

%description utils
Utilities for interacting with wallaby

%package -n ruby-wallaby
Summary: wallaby qmf api methods
Group: Applications/System
Requires: ruby(abi) = 1.8
Requires: ruby
Requires: ruby-qmf
BuildRequires: ruby

%description -n ruby-wallaby
Functions to communicate with wallaby over qmf

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{ruby_sitelib}/mrg/grid/config/dbmigrate
mkdir -p %{buildroot}/%{_bindir}
cp -f bin/wallaby-dump %{buildroot}/%{_bindir}
cp -f bin/wallaby-load %{buildroot}/%{_bindir}
cp -f bin/wallaby-agent %{buildroot}/%{_bindir}
cp -f lib/mrg/grid/*.rb %{buildroot}/%{ruby_sitelib}/mrg/grid
cp -f lib/mrg/grid/config/*.rb %{buildroot}/%{ruby_sitelib}/mrg/grid/config
cp -f lib/mrg/grid/config/dbmigrate/*.rb %{buildroot}/%{ruby_sitelib}/mrg/grid/config/dbmigrate

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%doc LICENSE README.rdoc TODO VERSION
%defattr(0755,root,root,-)
%{_bindir}/wallaby-agent

%files utils
%defattr(-, root, root, -)
%doc LICENSE
%defattr(0755,root,root,-)
%{_bindir}/wallaby-load
%{_bindir}/wallaby-dump

%files -n ruby-wallaby
%defattr(-, root, root, -)
%{ruby_sitelib}/mrg/grid/config.rb
%{ruby_sitelib}/mrg/grid/config-client.rb
%{ruby_sitelib}/mrg/grid/config-proxies.rb
%{ruby_sitelib}/mrg/grid/config/ArcLabel.rb
%{ruby_sitelib}/mrg/grid/config/ArcUtils.rb
%{ruby_sitelib}/mrg/grid/config/Configuration.rb
%{ruby_sitelib}/mrg/grid/config/DirtyElement.rb
%{ruby_sitelib}/mrg/grid/config/Feature.rb
%{ruby_sitelib}/mrg/grid/config/Group.rb
%{ruby_sitelib}/mrg/grid/config/Node.rb
%{ruby_sitelib}/mrg/grid/config/NodeMembership.rb
%{ruby_sitelib}/mrg/grid/config/Parameter.rb
%{ruby_sitelib}/mrg/grid/config/QmfUtils.rb
%{ruby_sitelib}/mrg/grid/config/Snapshot.rb
%{ruby_sitelib}/mrg/grid/config/Store.rb
%{ruby_sitelib}/mrg/grid/config/Subsystem.rb
%{ruby_sitelib}/mrg/grid/config/dbmeta.rb
%{ruby_sitelib}/mrg/grid/config/dbmigrate/1.rb
%{ruby_sitelib}/mrg/grid/config/dbmigrate/2.rb

%changelog
* Wed Feb 10 2010 rrati <rrati@redhat> - 0.1.0-0.1
- Initial package
