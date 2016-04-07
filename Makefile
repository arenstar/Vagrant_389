HOST=$(shell hostname)
run:
	puppet apply --modulepath=/etc/puppet/modules -v --show_diff ./puppet/389-$(HOST).pp
