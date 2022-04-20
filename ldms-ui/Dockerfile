FROM ovishpc/ldms-agg

SHELL [ "/bin/bash", "-c" ]

RUN yum install -y httpd mod_wsgi python3-mod_wsgi ; \
    yum clean all ;
RUN pip3 install django==2.1.15 django-cors-headers==2.4.1 ;

COPY --chown=root:root .ovis /opt/ovis

RUN mkdir -p /var/log/sosgui
RUN chown apache:apache /var/log/sosgui

COPY --chown=root:root conf/sosgui.conf /etc/httpd/conf.d/
COPY --chown=apache:apache conf/settings.py /opt/ovis/ui/sosgui/

RUN set -e ; \
    set -x ; \
    . /opt/ovis/etc/profile.d/set-ovis-variables.sh ; \
    cd /opt/ovis/ui ; \
    python3 manage.py migrate ; \
    python3 manage.py migrate --run-syncdb ; \
    echo "from sosdb_auth.models import SosdbUser; SosdbUser.objects.create_superuser('admin', 'root@localhost', 'admin')" \
    | python3 manage.py shell ;

RUN chown apache:apache -R /opt/ovis/ui/ /var/log/sosgui/

COPY --chown=root:root scripts-ui/start-ui.sh /docker/

ENTRYPOINT [ "/docker/start-ui.sh" ]
