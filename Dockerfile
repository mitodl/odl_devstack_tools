FROM edxops/edxapp:latest
USER root

ENV EDXAPPDIR=/edx/app/edxapp
ENV EDXVARDIR=/edx/var/edxapp
ENV HELPERDIR=$EDXAPPDIR/helper
ENV CONTAINERSSHDIR=~/.ssh
ENV HOSTSSHDIR=./ssh

RUN echo "" >> ~/.bashrc
RUN echo "# My overrides" >> ~/.bashrc
RUN echo "stty sane" >> ~/.bashrc

RUN /bin/bash -c 'mkdir $HELPERDIR $HELPERDIR/configpatch $HELPERDIR/requirements && sudo chown -R edxapp:edxapp $HELPERDIR'
RUN /bin/bash -c 'echo "###### USING VENV PIP ######"'
RUN /bin/bash -c 'cd $EDXAPPDIR && source $EDXAPPDIR/edxapp_env \
  && /edx/app/edxapp/venvs/edxapp/bin/pip install pdbpp ipython jsonpatch --isolated'
  
# Create course export directory (required for course export functionality)
RUN /bin/bash -c 'mkdir $EDXVARDIR/export_course_repos && chown -R edxapp:edxapp $EDXVARDIR/export_course_repos'

# Enable SSH access to github.mit.edu for Git course exports/imports
COPY $HOSTSSHDIR/id_rsa $CONTAINERSSHDIR/
COPY $HOSTSSHDIR/id_rsa.pub $CONTAINERSSHDIR/
RUN /bin/bash -c 'touch $CONTAINERSSHDIR/known_hosts \
  && chmod +w $CONTAINERSSHDIR/known_hosts \
  && ssh-keyscan github.mit.edu >> $CONTAINERSSHDIR/known_hosts \
  && sudo chown -R edxapp:edxapp $CONTAINERSSHDIR'
