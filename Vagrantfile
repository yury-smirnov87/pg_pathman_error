Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

   config.vm.provision "shell", inline: <<-SHELL
	yum -y update

	yum -y install java-1.8.0-openjdk.x86_64

	yum -y install maven

	yum -y install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm
	yum -y install postgresql10-server
	yum -y install pg_pathman10
	
	/usr/pgsql-10/bin/postgresql-10-setup initdb
	
	sed -i "s|^#listen_addresses =.*|listen_addresses = '*'|g" /var/lib/pgsql/10/data/postgresql.conf
	sed -i "s|^#shared_preload_libraries =.*|shared_preload_libraries = 'pg_pathman'|g" /var/lib/pgsql/10/data/postgresql.conf
	echo "host     all    all    192.168.33.1/24    md5" >> /var/lib/pgsql/10/data/pg_hba.conf
	
	systemctl enable postgresql-10.service
	systemctl start postgresql-10.service

	sudo -u postgres psql -c "alter user postgres with password '123Qwer';"
	sudo -u postgres psql -f /vagrant/target/classes/db_migration.sql

	cd /vagrant

	mvn clean package

	java -jar /vagrant/target/pg_pathman_error-0.0.1-SNAPSHOT.jar
   SHELL
end