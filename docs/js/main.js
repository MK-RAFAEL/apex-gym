// ===================== NAVBAR SCROLL STATE =====================
const navbar = document.getElementById("navbar");
const onScroll = () => {
  navbar.classList.toggle("scrolled", window.scrollY > 30);
};
document.addEventListener("scroll", onScroll, { passive: true });
onScroll();

// ===================== MOBILE MENU =====================
const hamburger = document.getElementById("hamburger");
const navLinks = document.getElementById("navLinks");

hamburger.addEventListener("click", () => {
  const isOpen = navLinks.classList.toggle("open");
  hamburger.classList.toggle("open", isOpen);
  hamburger.setAttribute("aria-expanded", String(isOpen));
  document.body.style.overflow = isOpen ? "hidden" : "";
});

navLinks.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", () => {
    navLinks.classList.remove("open");
    hamburger.classList.remove("open");
    hamburger.setAttribute("aria-expanded", "false");
    document.body.style.overflow = "";
  });
});

// ===================== ACTIVE NAV LINK ON SCROLL =====================
const sections = document.querySelectorAll("section[id]");
const navAnchors = document.querySelectorAll(".nav-link");

const navObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        navAnchors.forEach((a) => a.classList.remove("active"));
        const active = document.querySelector(`.nav-link[href="#${entry.target.id}"]`);
        if (active) active.classList.add("active");
      }
    });
  },
  { rootMargin: "-45% 0px -50% 0px", threshold: 0 }
);
sections.forEach((s) => navObserver.observe(s));

// ===================== SCROLL REVEAL =====================
const revealEls = document.querySelectorAll("[data-reveal]");
const revealObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        const delay = entry.target.dataset.revealDelay || 0;
        setTimeout(() => entry.target.classList.add("in-view"), Number(delay));
        revealObserver.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.15 }
);
revealEls.forEach((el) => revealObserver.observe(el));

// ===================== ANIMATED COUNTERS =====================
const counters = document.querySelectorAll("[data-count]");
const counterObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      const el = entry.target;
      const target = Number(el.dataset.count);
      const duration = 1400;
      const start = performance.now();

      const tick = (now) => {
        const progress = Math.min((now - start) / duration, 1);
        const eased = 1 - Math.pow(1 - progress, 3);
        el.textContent = Math.round(eased * target).toLocaleString("es-DO");
        if (progress < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
      counterObserver.unobserve(el);
    });
  },
  { threshold: 0.5 }
);
counters.forEach((el) => counterObserver.observe(el));

// ===================== CURSOR GLOW FOLLOW =====================
const cursorGlow = document.getElementById("cursorGlow");
const isFinePointer = window.matchMedia("(hover: hover) and (pointer: fine)").matches;

if (isFinePointer && cursorGlow) {
  let glowX = window.innerWidth / 2;
  let glowY = window.innerHeight / 2;
  let targetX = glowX;
  let targetY = glowY;

  document.addEventListener("mousemove", (e) => {
    targetX = e.clientX;
    targetY = e.clientY;
    cursorGlow.classList.add("active");
  });

  document.addEventListener("mouseleave", () => cursorGlow.classList.remove("active"));

  const animateGlow = () => {
    glowX += (targetX - glowX) * 0.12;
    glowY += (targetY - glowY) * 0.12;
    cursorGlow.style.transform = `translate(${glowX}px, ${glowY}px) translate(-50%, -50%)`;
    requestAnimationFrame(animateGlow);
  };
  animateGlow();
}

// ===================== HERO PARALLAX (mouse move) =====================
const visualStage = document.getElementById("visualStage");
const orb1 = document.getElementById("orb1");
const orb2 = document.getElementById("orb2");

if (isFinePointer && visualStage) {
  const floatCards = visualStage.querySelectorAll(".float-card");

  document.querySelector(".hero").addEventListener("mousemove", (e) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const relX = (e.clientX - rect.left) / rect.width - 0.5;
    const relY = (e.clientY - rect.top) / rect.height - 0.5;

    visualStage.style.transform = `rotateY(${relX * 10}deg) rotateX(${relY * -10}deg)`;

    floatCards.forEach((card) => {
      const depth = Number(card.dataset.depth) || 30;
      card.style.transform = `translate(${relX * depth}px, ${relY * depth}px)`;
    });

    if (orb1) orb1.style.transform = `translate(${relX * -30}px, ${relY * -30}px)`;
    if (orb2) orb2.style.transform = `translate(${relX * 30}px, ${relY * 30}px)`;
  });

  document.querySelector(".hero").addEventListener("mouseleave", () => {
    visualStage.style.transform = "rotateY(0deg) rotateX(0deg)";
    floatCards.forEach((card) => (card.style.transform = "translate(0, 0)"));
  });
}
if (visualStage) visualStage.style.transformStyle = "preserve-3d";

// ===================== 3D TILT CARDS =====================
if (isFinePointer) {
  document.querySelectorAll("[data-tilt]").forEach((card) => {
    card.addEventListener("mousemove", (e) => {
      const rect = card.getBoundingClientRect();
      const relX = (e.clientX - rect.left) / rect.width - 0.5;
      const relY = (e.clientY - rect.top) / rect.height - 0.5;
      card.style.transform = `perspective(800px) rotateY(${relX * 8}deg) rotateX(${relY * -8}deg) translateY(-4px)`;
    });
    card.addEventListener("mouseleave", () => {
      card.style.transform = "perspective(800px) rotateY(0deg) rotateX(0deg) translateY(0)";
    });
  });
}

// ===================== MAGNETIC BUTTONS =====================
if (isFinePointer) {
  document.querySelectorAll(".magnetic").forEach((btn) => {
    btn.addEventListener("mousemove", (e) => {
      const rect = btn.getBoundingClientRect();
      const relX = e.clientX - rect.left - rect.width / 2;
      const relY = e.clientY - rect.top - rect.height / 2;
      btn.style.transform = `translate(${relX * 0.25}px, ${relY * 0.35}px)`;
    });
    btn.addEventListener("mouseleave", () => {
      btn.style.transform = "translate(0, 0)";
    });
  });
}

// ===================== MARQUEE SEAMLESS LOOP =====================
const marqueeTrack = document.getElementById("marqueeTrack");
if (marqueeTrack) {
  marqueeTrack.innerHTML += marqueeTrack.innerHTML;
}

// ===================== PLAY BUTTON (placeholder) =====================
const playBtn = document.getElementById("playBtn");
if (playBtn) {
  playBtn.addEventListener("click", () => {
    document.querySelector("#instalaciones")?.scrollIntoView({ behavior: "smooth" });
  });
}
