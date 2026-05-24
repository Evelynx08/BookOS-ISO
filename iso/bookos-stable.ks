# BookOS Stable ISO — release builds, recommended
%include bookos-base.ks
# Override repo to stable channel
repo --name=bookos --baseurl=https://bookos.es/repo/fedora/$releasever/$basearch/stable/ --cost=10
