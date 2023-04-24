C=mtest-ui
OPTIONS=(
-dit --name ${C} --hostname ${C} --network test
-v /home/narate/projects/ldms-containers/test/test-maestro/files/dsosd.conf:/opt/ovis/etc/dsosd.conf
-v /home/narate/projects/ldms-containers/test/test-maestro/files/settings.py:/opt/ovis/ui/sosgui/settings.py
-v /home/narate/projects/ldms-containers/root:/root
-v /home/narate/projects/ldms-containers/ovis:/opt/ovis
--entrypoint /bin/bash --privileged --cap-add SYS_PTRACE --cap-add SYS_ADMIN
ovishpc/ldms-ui
)
docker run "${OPTIONS[@]}"
