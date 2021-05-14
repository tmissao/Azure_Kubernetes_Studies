FROM node:12 as build

# Create app directory
WORKDIR /opt/app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./

# RUN npm install
# # If you are building your code for production
RUN npm install --production && npm cache clean --force

# Bundle app source
COPY . .

FROM node:12-alpine

COPY --from=build /opt/app /opt/app

WORKDIR /opt/app

CMD [ "npm", "start" ]
