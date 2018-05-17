FROM edxops/edxapp:latest
USER root

ENV EDXAPPDIR=/edx/app/edxapp
ENV EDXVARDIR=/edx/var/edxapp
ENV CONTAINERHOMEDIR=/root
ENV CONTAINERSSHDIR=$CONTAINERHOMEDIR/.ssh
# Should match the DEVSTACK_CONTAINER_HELPER_DIR environment variable
ENV HELPERDIR=$EDXAPPDIR/helper
ENV HOSTSSHDIR=./ssh

RUN echo "" >> ~/.bashrc
RUN echo "# My overrides" >> ~/.bashrc
RUN echo "stty sane" >> ~/.bashrc

RUN /bin/bash -c 'mkdir $HELPERDIR $HELPERDIR/configpatch $HELPERDIR/requirements && sudo chown -R edxapp:edxapp $HELPERDIR'
COPY ./image_requirements.txt $HELPERDIR/requirements
RUN /bin/bash -c 'cd $EDXAPPDIR && source $EDXAPPDIR/edxapp_env \
  && /edx/app/edxapp/venvs/edxapp/bin/pip install -r $HELPERDIR/requirements/image_requirements.txt --isolated'
  
# Create course export directory (required for course export functionality)
RUN /bin/bash -c 'mkdir $EDXVARDIR/export_course_repos && chown -R edxapp:edxapp $EDXVARDIR/export_course_repos'
RUN /bin/bash -c 'if [ ! -d $CONTAINERSSHDIR ]; then mkdir $CONTAINERSSHDIR; fi'

# Enable SSH access to github.mit.edu for Git course exports/imports
COPY $HOSTSSHDIR/id_rsa* $CONTAINERSSHDIR/
RUN /bin/bash -c 'touch $CONTAINERSSHDIR/known_hosts \
  && chmod +w $CONTAINERSSHDIR/known_hosts \
  && ssh-keyscan github.mit.edu >> $CONTAINERSSHDIR/known_hosts \
  && sudo chown -R edxapp:edxapp $CONTAINERSSHDIR'
