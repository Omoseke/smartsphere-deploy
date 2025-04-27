document.addEventListener('DOMContentLoaded', function() {
  // Show animated loading screen with brand logo reveal
  function showLoadingScreen() {
    // Create a loading overlay if it doesn't exist
    if (!document.querySelector('.page-loading-overlay')) {
      const overlay = document.createElement('div');
      overlay.className = 'page-loading-overlay';
      overlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: linear-gradient(45deg, #e6e6fa, #fff);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 9999;
        transition: opacity 0.5s ease-out;
      `;
      
      // Create loading content container
      const loadingContent = document.createElement('div');
      loadingContent.className = 'loading-content';
      loadingContent.style.cssText = `
        text-align: center;
        transform: scale(0.8);
        opacity: 0;
        transition: all 0.8s cubic-bezier(0.19, 1, 0.22, 1);
      `;
      
      // Create company logo
      const logo = document.createElement('div');
      logo.className = 'loading-logo';
      logo.innerHTML = `<svg width="100" height="100" viewBox="0 0 100 100">
        <circle cx="50" cy="50" r="40" fill="none" stroke="#ff5555" stroke-width="8" stroke-dasharray="251" stroke-dashoffset="251">
          <animate attributeName="stroke-dashoffset" from="251" to="0" dur="1.5s" fill="freeze" />
        </circle>
        <path d="M35,35 L65,65 M35,65 L65,35" stroke="#333" stroke-width="8" stroke-linecap="round" stroke-dasharray="45" stroke-dashoffset="45">
          <animate attributeName="stroke-dashoffset" from="45" to="0" dur="0.8s" begin="0.7s" fill="freeze" />
        </path>
      </svg>`;
      
      // Create loading text
      const loadingText = document.createElement('div');
      loadingText.className = 'loading-text';
      loadingText.innerHTML = `<h2 style="font-size: 24px; margin: 20px 0; color: #333;">SmartSphere</h2>
        <p style="font-size: 16px; color: #666;">Loading experience...</p>`;
      
      // Create progress bar
      const progressBar = document.createElement('div');
      progressBar.className = 'loading-progress';
      progressBar.style.cssText = `
        width: 200px;
        height: 4px;
        background: #eee;
        border-radius: 4px;
        margin: 20px auto;
        overflow: hidden;
      `;
      
      const progressFill = document.createElement('div');
      progressFill.style.cssText = `
        height: 100%;
        width: 0%;
        background: linear-gradient(to right, #ff5555, #ff8855);
        transition: width 2s cubic-bezier(0.19, 1, 0.22, 1);
      `;
      progressBar.appendChild(progressFill);
      
      // Add everything to DOM
      loadingContent.appendChild(logo);
      loadingContent.appendChild(loadingText);
      loadingContent.appendChild(progressBar);
      overlay.appendChild(loadingContent);
      document.body.appendChild(overlay);
      
      // Trigger animations
      setTimeout(() => {
        loadingContent.style.transform = 'scale(1)';
        loadingContent.style.opacity = '1';
      }, 100);
      
      setTimeout(() => {
        progressFill.style.width = '100%';
      }, 300);
      
      // Remove the overlay after loading completes
      setTimeout(() => {
        overlay.style.opacity = '0';
        setTimeout(() => {
          document.body.removeChild(overlay);
        }, 500);
      }, 2500);
    }
  }
  
  // Call loading screen on page load
  showLoadingScreen();
  
  // Contextual Color Palette Generator for Trusted Section
  function generateContextualColorPalette() {
    const root = document.documentElement;
    const hour = new Date().getHours();
    const date = new Date();
    
    // Calculate day of year (0-365)
    const start = new Date(date.getFullYear(), 0, 0);
    const diff = date - start;
    const oneDay = 1000 * 60 * 60 * 24;
    const dayOfYear = Math.floor(diff / oneDay);
    
    // Generate a seasonal hue shift based on day of year
    const seasonalHue = Math.floor((dayOfYear / 365) * 60); // 0-60 degree hue shift
    
    // Morning (5am-11am): Warm, energetic colors with seasonal adjustment
    if (hour >= 5 && hour < 11) {
      root.style.setProperty('--time-gradient-start', `hsl(${30 + seasonalHue}, 100%, 98%)`);
      root.style.setProperty('--time-gradient-end', `hsl(${20 + seasonalHue}, 90%, 95%)`);
      root.style.setProperty('--time-gradient-dark-start', `hsl(${30 + seasonalHue}, 30%, 15%)`);
      root.style.setProperty('--time-gradient-dark-end', `hsl(${20 + seasonalHue}, 25%, 20%)`);
    } 
    // Midday (11am-4pm): Bright, productive colors
    else if (hour >= 11 && hour < 16) {
      root.style.setProperty('--time-gradient-start', `hsl(${210 + seasonalHue}, 100%, 98%)`);
      root.style.setProperty('--time-gradient-end', `hsl(${220 + seasonalHue}, 90%, 95%)`);
      root.style.setProperty('--time-gradient-dark-start', `hsl(${210 + seasonalHue}, 30%, 15%)`);
      root.style.setProperty('--time-gradient-dark-end', `hsl(${220 + seasonalHue}, 25%, 20%)`);
    } 
    // Evening (4pm-8pm): Soothing transition colors
    else if (hour >= 16 && hour < 20) {
      root.style.setProperty('--time-gradient-start', `hsl(${260 + seasonalHue}, 100%, 98%)`);
      root.style.setProperty('--time-gradient-end', `hsl(${280 + seasonalHue}, 90%, 95%)`);
      root.style.setProperty('--time-gradient-dark-start', `hsl(${260 + seasonalHue}, 30%, 15%)`);
      root.style.setProperty('--time-gradient-dark-end', `hsl(${280 + seasonalHue}, 25%, 20%)`);
    } 
    // Night (8pm-5am): Calm, relaxing colors
    else {
      root.style.setProperty('--time-gradient-start', `hsl(${240 + seasonalHue}, 100%, 98%)`);
      root.style.setProperty('--time-gradient-end', `hsl(${230 + seasonalHue}, 90%, 95%)`);
      root.style.setProperty('--time-gradient-dark-start', `hsl(${240 + seasonalHue}, 30%, 15%)`);
      root.style.setProperty('--time-gradient-dark-end', `hsl(${230 + seasonalHue}, 25%, 20%)`);
    }
  }
  
  // Update color palette immediately and every 15 minutes
  generateContextualColorPalette();
  setInterval(generateContextualColorPalette, 15 * 60 * 1000);
  
  // Skeleton Loading Animation
  function simulateLoading() {
    const loaders = document.querySelectorAll('.content-loader');
    const realContents = document.querySelectorAll('.real-content');
    
    // Show skeleton loaders first
    loaders.forEach(loader => {
      loader.classList.remove('hidden');
    });
    
    realContents.forEach(content => {
      content.classList.remove('loaded');
    });
    
    // Simulate different loading times for different sections
    setTimeout(() => {
      // Hide feature loader and show real feature content
      const featureLoader = document.querySelector('.feature-loader');
      const featureContent = document.querySelector('.mySwiper.real-content');
      
      if (featureLoader && featureContent) {
        featureLoader.classList.add('hidden');
        featureContent.classList.add('loaded');
      }
    }, 1000);
    
    setTimeout(() => {
      // Hide testimonial loader and show real testimonial content
      const testimonialLoader = document.querySelector('.testimonial-loader');
      const testimonialContent = document.querySelector('.testimonial-cards.real-content');
      
      if (testimonialLoader && testimonialContent) {
        testimonialLoader.classList.add('hidden');
        testimonialContent.classList.add('loaded');
      }
    }, 1800);
    
    setTimeout(() => {
      // Hide CTA loader and show real CTA content
      const ctaLoader = document.querySelector('.cta-loader');
      const ctaContent = document.querySelector('.cta-content.real-content');
      
      if (ctaLoader && ctaContent) {
        ctaLoader.classList.add('hidden');
        ctaContent.classList.add('loaded');
      }
    }, 2500);
  }
  
  // Call the loading function when page loads
  simulateLoading();
  
  // Demo the skeleton loader when clicking buttons
  document.querySelectorAll('.btn').forEach(button => {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      
      // For demo purposes, show loading skeletons again
      simulateLoading();
      
      // Show a simple alert after the loading completes
      setTimeout(() => {
        alert('Feature Coming Soon!');
      }, 2500);
    });
  });
  
  // Dark Mode Toggle Functionality
  const themeSwitchDesktop = document.getElementById('checkbox');
  const themeSwitchMobile = document.getElementById('checkbox-mobile');
  const body = document.body;
  
  // Check for saved theme preference or prefer-color-scheme
  const prefersDarkScheme = window.matchMedia('(prefers-color-scheme: dark)');
  const currentTheme = localStorage.getItem('theme');
  
  // Function to update theme switches
  const updateThemeSwitches = (isDark) => {
    if (themeSwitchDesktop) themeSwitchDesktop.checked = isDark;
    if (themeSwitchMobile) themeSwitchMobile.checked = isDark;
  };
  
  // Apply theme based on saved preference
  if (currentTheme === 'dark') {
    body.classList.add('dark-mode');
    updateThemeSwitches(true);
  } else if (currentTheme === 'light') {
    body.classList.remove('dark-mode');
    updateThemeSwitches(false);
  } else {
    // Default to light mode even if OS prefers dark
    body.classList.remove('dark-mode');
    updateThemeSwitches(false);
    localStorage.setItem('theme', 'light');
  }
  
  // Theme Switch Event Listeners
  const handleThemeChange = function(event) {
    const isDark = event.target.checked;
    
    if (isDark) {
      body.classList.add('dark-mode');
      localStorage.setItem('theme', 'dark');
    } else {
      body.classList.remove('dark-mode');
      localStorage.setItem('theme', 'light');
    }
    
    // Keep switches in sync
    updateThemeSwitches(isDark);
    
    // Add smooth transition animation
    body.style.transition = 'background 0.5s ease-in-out, color 0.5s ease-in-out';
  };
  
  // Add listeners to both switches
  if (themeSwitchDesktop) {
    themeSwitchDesktop.addEventListener('change', handleThemeChange);
  }
  
  if (themeSwitchMobile) {
    themeSwitchMobile.addEventListener('change', handleThemeChange);
  }
  // Hamburger menu toggle
  const hamburger = document.querySelector('.hamburger-menu');
  const navLinks = document.querySelector('.nav-links');
  const mobileNav = document.getElementById('mobile-nav');

  hamburger.addEventListener('click', () => {
    navLinks.classList.toggle('show');
    hamburger.classList.toggle('open');
    if (mobileNav) {
      mobileNav.classList.toggle('show');
    }
  });

  // Smooth scrolling for all anchor links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        // Add a smooth scrolling with a subtle easing effect
        window.scrollTo({
          top: target.offsetTop - 80, // Offset for header
          behavior: 'smooth'
        });
      }
    });
  });
  
  // Section reveal animation on scroll
  const sections = document.querySelectorAll('section');
  const observerOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.15 // When 15% of the section is visible
  };
  
  // Set card index for staggered animation
  const featureCards = document.querySelectorAll('.feature-card');
  featureCards.forEach((card, index) => {
    card.style.setProperty('--card-index', index);
  });
  
  const sectionObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        
        // For sections with feature cards, animate them with staggered timing
        if (entry.target.querySelectorAll('.feature-card').length > 0) {
          const cards = entry.target.querySelectorAll('.feature-card');
          cards.forEach((card, index) => {
            // Add staggered delay for each card
            setTimeout(() => {
              card.classList.add('visible');
            }, 150 * index); // 150ms delay between each card
          });
        }
        
        // Optional: Stop observing after animation is applied
        // observer.unobserve(entry.target);
      } else {
        // Comment this line if you want sections to stay visible once revealed
        // entry.target.classList.remove('visible');
      }
    });
  }, observerOptions);
  
  sections.forEach(section => {
    sectionObserver.observe(section);
    // Initially hide all sections
    section.classList.remove('visible');
  });
  
  // Scroll-triggered logo parallax effect for trusted section
  function initLogoParallaxEffect() {
    const logoSection = document.querySelector('.trusted-container');
    const logos = document.querySelectorAll('.brand-logo');
    
    if (logoSection && logos.length > 0) {
      // Set initial parallax values for each logo
      logos.forEach((logo, index) => {
        // Alternate between positive and negative parallax values for more dynamic effect
        const parallaxFactor = index % 2 === 0 ? 0.15 : -0.15;
        logo.setAttribute('data-parallax', parallaxFactor);
        // Add accessibility attributes for enhanced logo navigation
        logo.setAttribute('tabindex', '0');
        logo.setAttribute('role', 'button');
        logo.setAttribute('aria-label', `Partner logo ${index + 1}, ${logo.getAttribute('data-tooltip') || 'Trusted partner'}`);
      });
      
      // Add scroll event listener for parallax effect
      window.addEventListener('scroll', () => {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        const sectionOffset = logoSection.offsetTop;
        const sectionHeight = logoSection.offsetHeight;
        
        // Only apply effect when the section is in view
        if (scrollTop + window.innerHeight > sectionOffset && 
            scrollTop < sectionOffset + sectionHeight) {
          
          const sectionProgress = (scrollTop + window.innerHeight - sectionOffset) / (window.innerHeight + sectionHeight);
          
          // Apply parallax effect to each logo
          logos.forEach((logo) => {
            const parallaxFactor = parseFloat(logo.getAttribute('data-parallax')) || 0;
            const translateY = (sectionProgress * 100 * parallaxFactor).toFixed(2);
            const translateX = (sectionProgress * 50 * parallaxFactor).toFixed(2);
            const scale = (1 + sectionProgress * 0.1 * Math.abs(parallaxFactor)).toFixed(2);
            
            // Apply transform with smooth transition
            logo.style.transform = `translate(${translateX}px, ${translateY}px) scale(${scale})`;
          });
        }
      });
      
      // Add keyboard navigation for accessibility
      logos.forEach((logo) => {
        logo.addEventListener('keydown', (e) => {
          // Activate logo on Enter or Space key
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            // Trigger the same effect as hover
            logo.style.animation = 'wiggle 0.6s ease-in-out, pulse 1.5s infinite alternate';
            
            // Show tooltip info via alert for keyboard users
            const tooltipText = logo.getAttribute('data-tooltip') || 'Trusted partner';
            setTimeout(() => {
              alert(`Partner: ${tooltipText}`);
            }, 300);
          }
        });
      });
    }
  }
  
  // Initialize parallax effect after a short delay to ensure DOM is ready
  setTimeout(initLogoParallaxEffect, 500);

  // Back to Top button functionality
  const backToTopBtn = document.getElementById('backToTopBtn');
  if (backToTopBtn) {
    // Scroll to top when clicked
    backToTopBtn.addEventListener('click', function() {
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    });
    
    // Show/hide button based on scroll position with a lazy appearance
    window.addEventListener('scroll', function() {
      if (window.scrollY > 300) {
        // Add show-back-to-top class to make it visible
        backToTopBtn.classList.add('show-back-to-top');
      } else {
        // Remove show-back-to-top class to hide it
        backToTopBtn.classList.remove('show-back-to-top');
      }
    });
  }

  // Add Click/Tap Effect on Cards & Icons
  document.querySelectorAll(".feature-card").forEach(card => {
    card.addEventListener("click", function () {
      document.querySelectorAll(".feature-card").forEach(c => c.classList.remove("active"));
      this.classList.add("active");
    });
  });

  // This is now handled by the simulateLoading function above

  // ----- Swiper Slider & Pagination Fixes -----
  // Initialize Swiper (ensure Swiper library is loaded)
  if (typeof Swiper !== "undefined") {
    new Swiper(".swiper", {
      loop: false, // Disable loop
      loopedSlides: 0, // Explicitly set to 0 to disable loop completely
      autoplay: false, // No autoplay - users must use navigation buttons
      speed: 600, // Smooth transition speed
      // Use consistent card display for both mobile and desktop
      slidesPerView: 'auto', // Allows us to control with CSS
      spaceBetween: 20, // Gap between slides
      centeredSlides: false, // Don't center slides
      pagination: {
        el: '.swiper-pagination',
        clickable: true,
        dynamicBullets: true
      },
      navigation: {
        nextEl: ".swiper-button-next",
        prevEl: ".swiper-button-prev",
      },
      // Handle all events in one on object
      on: {
        slideChange: function() {
          // Update all slides to have consistent styling
          const slides = document.querySelectorAll('.swiper-slide');
          const totalVisible = window.innerWidth < 768 ? 1 : 3; // Show 1 on mobile, 3 on desktop
          
          // Show a fixed number of cards based on screen size
          slides.forEach((slide, index) => {
            // Active card logic
            if (index >= this.activeIndex && index < this.activeIndex + totalVisible) {
              slide.style.opacity = "1";
              slide.style.visibility = "visible";
              slide.classList.add('active-slide');
            } else {
              slide.style.opacity = "0.4"; // Semi-transparent for inactive
              slide.style.visibility = "visible";
              slide.classList.remove('active-slide');
            }
          });
          
          // Update counter display
          const currentSlideElement = document.querySelector('.current-slide');
          if (currentSlideElement) {
            currentSlideElement.textContent = this.activeIndex + 1;
            
            // Add highlight animation when number changes
            currentSlideElement.style.animation = 'none';
            setTimeout(() => {
              currentSlideElement.style.animation = 'numberPulse 0.5s';
            }, 10);
          }
        },
        init: function() {
          // Initialize the slides
          const slides = document.querySelectorAll('.swiper-slide');
          
          // Set the total slides count
          const totalSlidesElement = document.querySelector('.total-slides');
          if (totalSlidesElement) {
            totalSlidesElement.textContent = slides.length;
          }
          
          // Set initial current slide (1-based, not 0-based)
          const currentSlideElement = document.querySelector('.current-slide');
          if (currentSlideElement) {
            currentSlideElement.textContent = '1';
          }
          
          // Make all slides visible initially
          slides.forEach((slide, index) => {
            // Show first 3 slides on desktop or first slide on mobile
            const totalVisible = window.innerWidth < 768 ? 1 : 3;
            if (index < totalVisible) {
              slide.style.opacity = "1";
              slide.style.visibility = "visible";
              slide.classList.add('active-slide');
            } else {
              slide.style.opacity = "0.4";
              slide.style.visibility = "visible";
              slide.classList.remove('active-slide');
            }
          });
        },
        resize: function() {
          // Re-evaluate what slides should be visible when screen size changes
          const slides = document.querySelectorAll('.swiper-slide');
          const totalVisible = window.innerWidth < 768 ? 1 : 3;
          
          slides.forEach((slide, index) => {
            if (index >= this.activeIndex && index < this.activeIndex + totalVisible) {
              slide.style.opacity = "1";
              slide.style.visibility = "visible";
              slide.classList.add('active-slide');
            } else {
              slide.style.opacity = "0.4";
              slide.style.visibility = "visible";
              slide.classList.remove('active-slide');
            }
          });
        }
      },
      grabCursor: true,
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