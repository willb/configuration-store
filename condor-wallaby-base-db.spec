%define rel 0.3

Summary: Base condor database for wallaby
Name: condor-wallaby-base-db
Version: 1.1
Release: %{rel}%{?dist}
Group: Applications/System
License: ASL 2.0
URL: http://git.fedorahosted.org/git/grid/wallaby-base-db.git
Source0: %{name}-%{version}-%{rel}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: wallaby-utils
BuildArch: noarch

%description
A default database to be loaded into wallaby that provides configuration
options for a condor pool

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{_var}/lib/wallaby/snapshots
cp condor-base-db.snapshot %{buildroot}/%{_var}/lib/wallaby/snapshots

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%doc LICENSE
%{_var}/lib/wallaby/snapshots/condor-base-db.snapshot

%changelog
* Tue Mar 09 2010 rrati <rrati@redhat> - 1.1-0.3
- Added LL_DAEMON to LowLatency feature
- Added JobHooks feature and LowLatency depends upon it

* Thu Mar 04 2010 rrati <rrati@redhat> - 1.1-0.2
- Fixed revision history dates

* Thu Mar 04 2010 rrati <rrati@redhat> - 1.1-0.1
- Added feature NodeAccess, and all features affecting DAEMON_LIST depend
  upon it now
- Changed DynamicProvisioning -> DynamicSlots
- Added LIBVIRT_XML_SCRIPT param and added it to VMUniverse
- Set COLLECTOR_NAME = $(CONDOR_HOST)
- Removed ALLOW_WRITE_DAEMON, ALLOW_READ_STARTD, ALLOW_READ_COLLECTOR,
  ALLOW_READ_DAEMON, ALLOW_WRITE_COLLECTOR, ALLOW_WRITE_STARTD params
- FETCHWORKDELAY now requires a daemon restart when changed

* Wed Feb 24 2010 rrati <rrati@redhat> - 1.0-0.4
- Fixed location of StartdPlugin for ExecuteNode

* Tue Feb 23 2010 rrati <rrati@redhat> - 1.0-0.3
- Added UID_DOMAIN and FILESYSTEM_DOMAIN params & features that use them

* Fri Feb 19 2010 rrati <rrati@redhat> - 1.0-0.2
- Removed default values for parameters that must be set when used

* Wed Feb 11 2010 rrati <rrati@redhat> - 1.0-0.1
- Initial package
