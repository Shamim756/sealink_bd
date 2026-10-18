# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY . .

# Dependencies get and build
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Nginx-এর ডিফল্ট কনফিগারেশন রিমুভ করা
RUN rm -rf /usr/share/nginx/html/*

# Build করা ফাইলগুলো কপি করা
COPY --from=build /app/build/web /usr/share/nginx/html

# কাস্টম Nginx config কপি করা (রাউটিং ঠিক রাখার জন্য)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]