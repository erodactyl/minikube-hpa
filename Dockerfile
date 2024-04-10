FROM node:18 as base

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
CMD [ "node", "dist/index.js" ]
