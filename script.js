document.addEventListener('DOMContentLoaded', function() {
    const hamburger = document.querySelector('.hamburger-menu');
    const navLinks = document.querySelector('.nav-links');

    hamburger.addEventListener('click', () => {
      navLinks.classList.toggle('show');
      hamburger.classList.toggle('open');
    });
  });
  
  // Function to scroll back to the top
function scrollToTop() {
    window.scrollTo({
        top: 0,
        behavior: 'smooth'
    });
}

// Show the "Back to Top" button when scrolling down
window.onscroll = function() {
    let button = document.querySelector('.back-to-top');
    if (document.body.scrollTop > 50 || document.documentElement.scrollTop > 50) {
        button.style.display = 'block';
    } else {
        button.style.display = 'none';
    }
};