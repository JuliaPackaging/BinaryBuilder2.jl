#include <stdio.h>

void foo(){
    // This is where the magic happens
    printf("not so magical!\n");
}

/*
 * This long comment exists purely to force diffing algorithms to split
 * changes up into two hunks, so that we can test `atomic_patch` properly.
 * To ensure this is the case, I will now paste some `lorem ipsum` here:
 *
 * Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur consequat
 * rutrum sem, egestas ultricies turpis porttitor non. Integer tellus dolor,
 * aliquet at mattis a, pharetra in turpis. Ut ultricies metus et lacus ornare
 * sodales non vitae lorem. Nulla accumsan lacinia justo sed interdum. Mauris
 * sapien urna, malesuada et est at, mollis scelerisque libero. Donec sit amet
 * posuere ligula. Ut semper quis tortor sit amet cursus. Nunc feugiat ut velit
 * at aliquam. Proin semper in felis eget blandit. Nulla nisl purus, aliquet eu
 * justo fringilla, tempor sagittis justo. Vivamus vestibulum porta arcu et
 * dignissim. Fusce et pulvinar diam.
 */


int main() {
    // Do something cool here
    foo();
}
