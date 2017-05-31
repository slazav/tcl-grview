%define teaname GrapheneViewer
%define major 1.0

Name: tcl-grview
Version: 1.0
Release: alt1
BuildArch: noarch

Summary: GrapheneViewer library, a viewer for Graphene databases
Group: System/Libraries
Source: %name-%version.tar
License: Unknown

Requires: tcl

%description
tcl-grview -- GrapheneViewer library, a viewer for Graphene databases
%prep
%setup -q

%build
mkdir -p %buildroot/%_tcldatadir/%teaname
install -m644 *.tcl %buildroot/%_tcldatadir/%teaname

%files
%dir %_tcldatadir/%teaname
%_tcldatadir/%teaname/*.tcl

%changelog
