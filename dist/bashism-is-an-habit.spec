Name:           bashism-is-an-habit
Version:        0.1
Release:        1%{?dist}
Summary:        Experiments with shell function libraries.

License:        AGPLv3+
URL:            https://github.com/dbolcioni/bashism-is-an-habit
Source0:        bashism-is-an-habit-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  coreutils >= 8.31

%description
Experiments with shell function libraries.

%prep
%autosetup


%build


%install
rm -rf %{buildroot}
ls
install -m 0644 -D -t %{buildroot}%{_bindir} src/bin/*.bash


%files
%license LICENSE
%doc notes/location
%{_bindir}/*



%changelog
* Sun Nov 17 2019 Davide Bolcioni <dbolcioni@users.noreply.github.com>
- Initial packaging
