FROM alpine:3.8 as build-client
RUN apk add --no-cache npm python3 make gcc g++
WORKDIR /build
COPY client/package*.json ./
RUN npm ci
COPY client .
RUN npm run build

FROM alpine:3.8 as build-server
RUN apk add --no-cache npm
WORKDIR /build
COPY server .
RUN npm i --prod

FROM alpine:3.8 as run
ARG USER=default
ENV HOME /home/$USER
RUN apk add --no-cache nodejs \
    && apk add --update sudo \
    && adduser -D $USER \
    && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER \
    && mkdir /app \
    && chown $USER /app
USER $USER
WORKDIR /app
ENV NODE_ENV=production
EXPOSE 3000
CMD [ "node", "src/app.js" ]
COPY --chown=$USER --from=build-server /build .
COPY --chown=$USER --from=build-client /build/dist ./public