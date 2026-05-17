# Pull the baseimage.
FROM jlesage/baseimage-gui:ubuntu-24.04-v4

# Install xterm.
RUN add-pkg xterm

# Copy the start script.
COPY startapp.sh /startapp.sh

# Set the application name.
RUN set-cont-env APP_NAME "Xterm"