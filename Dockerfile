FROM node:alpine as base

# Create app directory
WORKDIR /usr/src/app

COPY package*.json ./

FROM base as build

# Install app dependencies
RUN npm ci

# Bundle app source
COPY . .
RUN npm run build

FROM build as prod

ENV NODE_ENV=production

# Remove dev dependencies
RUN npm prune

EXPOSE 3000

RUN chown -R node:node /usr/src/app
USER node

CMD [ "node", "dist/index.js" ]
