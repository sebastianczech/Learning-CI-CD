FROM node:14-alpine
RUN mkdir -p /usr/src/app/node_modules && chown -R node:node /usr/src/app
WORKDIR /usr/src/app
COPY web_app/package*.json ./
USER node
RUN npm install
COPY web_app/app.js .
EXPOSE 3000
CMD [ "node", "app.js" ]