  // Mobile menu toggle
  // Selecting elements
  const hamburger = document.querySelector(".hamburger");
  const mobileNav = document.querySelector(".mobile-nav");
  const navLinks = document.querySelectorAll(".mobile-nav a");  

hamburger.addEventListener('click', () => {
navLinks.classList.toggle('show');
});

// Selecting elements
const mobileNav = document.querySelector(".mobile-nav");

// Toggle mobile menu
hamburger.addEventListener("click", () => {
    mobileNav.classList.toggle("show-nav");
});

// Close menu when a link is clicked (for smooth scrolling)
navLinks.forEach(link => {
    link.addEventListener("click", () => {
        mobileNav.classList.remove("show-nav");
    });
});

// Smooth scrolling for desktop navigation
document.querySelectorAll("nav ul li a").forEach(anchor => {
    anchor.addEventListener("click", function (e) {
        e.preventDefault();
        const targetId = this.getAttribute("href").substring(1);
        const targetElement = document.getElementById(targetId);

        window.scrollTo({
            top: targetElement.offsetTop - 70,
            behavior: "smooth"
        });
    });
});

// Adjust header on scroll (Shrink effect)
window.addEventListener("scroll", () => {
    const header = document.querySelector("header");
    if (window.scrollY > 50) {
        header.style.padding = "15px 0";
        header.style.boxShadow = "0px 4px 10px rgba(0, 0, 0, 0.2)";
    } else {
        header.style.padding = "20px 0";
        header.style.boxShadow = "0px 4px 6px rgba(0, 0, 0, 0.1)";
    }
});

// Lazy loading images for better performance
document.addEventListener("DOMContentLoaded", () => {
    const lazyImages = document.querySelectorAll("img[data-src]");
    const observer = new IntersectionObserver(entries => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.removeAttribute("data-src");
                observer.unobserve(img);
            }
        });
    });

    lazyImages.forEach(img => {
        observer.observe(img);
    });
});

// Back to top button functionality
const backToTop = document.createElement("button");
backToTop.innerText = "↑";
backToTop.classList.add("back-to-top");
document.body.appendChild(backToTop);

backToTop.addEventListener("click", () => {
    window.scrollTo({
        top: 0,
        behavior: "smooth"
    });
});

window.addEventListener("scroll", () => {
    if (window.scrollY > 300) {
        backToTop.style.display = "block";
    } else {
        backToTop.style.display = "none";
    }
});




document.getElementById("hamburger-menu").addEventListener("click", function() {
    this.classList.toggle("open"); // Toggle hamburger icon animation
    const navLinks = document.getElementById("nav-links");
    const mobileNav = document.getElementById("mobile-nav");

    // Toggle the visibility of the navigation links
    if (navLinks.classList.contains("show")) {
        navLinks.classList.remove("show");
    } else {
        navLinks.classList.add("show");
    }

    // Show mobile nav on smaller screens
    if (mobileNav.classList.contains("show-nav")) {
        mobileNav.classList.remove("show-nav");
    } else {
        mobileNav.classList.add("show-nav");
    }
});
