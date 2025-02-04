document.addEventListener('DOMContentLoaded', function() {
  // Hamburger menu toggle
  const hamburger = document.querySelector('.hamburger-menu');
  const navLinks = document.querySelector('.nav-links');

  hamburger.addEventListener('click', () => {
    navLinks.classList.toggle('show');
    hamburger.classList.toggle('open');
  });

  // Add Click/Tap Effect on Cards & Icons
  document.querySelectorAll(".feature-card").forEach(card => {
    card.addEventListener("click", function () {
      document.querySelectorAll(".feature-card").forEach(c => c.classList.remove("active"));
      this.classList.add("active");
    });
  });

  // Buttons alert for feature coming soon
  const buttons = document.querySelectorAll(".btn");
  buttons.forEach((button) => {
    button.addEventListener("click", function () {
      alert("Feature Coming Soon!");
    });
  });

  // ----- Swiper Slider & Pagination Fixes -----
  // Initialize Swiper (ensure Swiper library is loaded)
  if (typeof Swiper !== "undefined") {
    new Swiper(".swiper", {
      loop: true, // Infinite loop
      autoplay: {
        delay: 3000,
        disableOnInteraction: false,
      },
      slidesPerView: "auto",
      centeredSlides: true,
      spaceBetween: 10,
      pagination: {
        el: ".swiper-pagination",
        clickable: true,
      },
      navigation: {
        nextEl: ".swiper-button-next",
        prevEl: ".swiper-button-prev",
      },
      breakpoints: {
        480: {
          slidesPerView: 1,
          spaceBetween: 5,
        },
        768: {
          slidesPerView: 2,
          spaceBetween: 10,
        },
        1024: {
          slidesPerView: 3,
          spaceBetween: 15,
        },
      },
    });
  }

  // Ensure navigation buttons work on touch devices
  document.querySelectorAll(".swiper-button-prev, .swiper-button-next").forEach(button => {
    button.addEventListener("touchstart", function (e) {
      e.preventDefault();
      this.click();
    });
  });

  // Feature card interaction for touch devices
  document.querySelectorAll(".feature-card").forEach(card => {
    card.addEventListener("click", function () {
      document.querySelectorAll(".feature-card").forEach(c => c.classList.remove("active"));
      this.classList.add("active");
    });
  });
  // ----- End Slider & Pagination Fixes -----

  // Resize canvas on window resize
  window.addEventListener('resize', () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  });

  // Particle: script.js (unchanged)
  class Particle {
    constructor(x, y, size, speedX, speedY, color) {
      this.x = x;
      this.y = y;
      this.size = size;
      this.speedX = speedX;
      this.speedY = speedY;
      this.color = color;
    }

    update() {
      this.x += this.speedX;
      this.y += this.speedY;
      this.size *= 0.98; // Gradually shrink
    }

    draw() {
      ctx.beginPath();
      ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
      ctx.fillStyle = this.color;
      ctx.fill();
    }
  }

  let canvas = document.getElementById('particleCanvas');
  let ctx = canvas.getContext('2d');
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;

  let cursorParticles = [];

  document.addEventListener('mousemove', (e) => {
    createCursorParticle(e.clientX, e.clientY);
  });

  function createCursorParticle(x, y) {
    let size = Math.random() * 3 + 2;
    let speedX = (Math.random() - 0.5) * 2;
    let speedY = (Math.random() - 0.5) * 2;
    let color = `hsl(${Math.random() * 360}, 100%, 60%)`;
    
    cursorParticles.push(new Particle(x, y, size, speedX, speedY, color));
  }

  function animateCursorParticles() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    cursorParticles.forEach((particle, index) => {
      particle.update();
      particle.draw();

      // Remove particles after they move off-screen
      if (particle.x < 0 || particle.x > canvas.width || particle.y < 0 || particle.y > canvas.height) {
        cursorParticles.splice(index, 1);
      }
    });

    requestAnimationFrame(animateCursorParticles);
  }

  animateCursorParticles();
});

document.addEventListener('DOMContentLoaded', function() {
  const backToTopBtn = document.querySelector('.back-to-top');

  if (backToTopBtn) {
    // Show button when user scrolls down
    window.addEventListener('scroll', () => {
      if (window.scrollY > 300) {
        backToTopBtn.classList.add('show-back-to-top');
      } else {
        backToTopBtn.classList.remove('show-back-to-top');
      }
    });

    // Smooth scroll to top
    backToTopBtn.addEventListener('click', () => {
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    });
  }
});