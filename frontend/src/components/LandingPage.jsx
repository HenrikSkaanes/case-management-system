import React from 'react';
import { useNavigate } from 'react-router-dom';
import './LandingPage.css';

const LandingPage = () => {
  const navigate = useNavigate();

  return (
    <div className="landing-page">
      {/* Header with employee login */}
      <header className="landing-header">
        <div className="logo-section">
          <div className="logo-icon">
            <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
              <rect width="32" height="32" rx="6" fill="url(#gradient)"/>
              <path d="M16 8L22 14L16 20L10 14L16 8Z" fill="white"/>
              <defs>
                <linearGradient id="gradient" x1="0" y1="0" x2="32" y2="32">
                  <stop offset="0%" stopColor="#0078D4"/>
                  <stop offset="100%" stopColor="#00BCF2"/>
                </linearGradient>
              </defs>
            </svg>
          </div>
          <div className="logo-text">
            <h1>Tax Wranglers</h1>
            <p className="tagline">Government Services</p>
          </div>
        </div>
        <button 
          className="employee-login-btn"
          onClick={() => navigate('/dashboard')}
        >
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
            <circle cx="10" cy="6" r="3" fill="currentColor"/>
            <path d="M4 16C4 12.686 6.686 10 10 10C13.314 10 16 12.686 16 16" stroke="currentColor" strokeWidth="2"/>
          </svg>
          Employee Portal
        </button>
      </header>

      {/* Hero Section */}
      <section className="hero-section">
        <div className="hero-content">
          <h2>Streamlined Tax Services</h2>
          <p className="hero-text">
            Professional assistance for all your tax needs. Our dedicated team is here to help you navigate regulations and optimize your returns.
          </p>
          <div className="hero-stats">
            <div className="stat-item">
              <div className="stat-number">24/7</div>
              <div className="stat-label">Support Available</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">15k+</div>
              <div className="stat-label">Cases Resolved</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">98%</div>
              <div className="stat-label">Satisfaction Rate</div>
            </div>
          </div>
        </div>
      </section>

      {/* Contact Information */}
      <section className="info-section">
        <div className="section-header">
          <h3>Get in Touch</h3>
          <p>We're here to help with all your tax-related inquiries</p>
        </div>

        <div className="info-grid">
          <div className="info-card">
            <div className="card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M3 5C3 3.89543 3.89543 3 5 3H8.27924C8.70967 3 9.09181 3.27543 9.22792 3.68377L10.7257 8.17721C10.8831 8.64932 10.6694 9.16531 10.2243 9.38787L7.96701 10.5165C9.06925 12.9612 11.0388 14.9308 13.4835 16.033L14.6121 13.7757C14.8347 13.3306 15.3507 13.1169 15.8228 13.2743L20.3162 14.7721C20.7246 14.9082 21 15.2903 21 15.7208V19C21 20.1046 20.1046 21 19 21H18C9.71573 21 3 14.2843 3 6V5Z" stroke="currentColor" strokeWidth="2"/>
              </svg>
            </div>
            <h4>Phone Support</h4>
            <p className="card-value">1-800-555-0199</p>
            <p className="card-description">Monday - Friday, 8:00 AM - 6:00 PM</p>
          </div>

          <div className="info-card">
            <div className="card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <rect x="3" y="5" width="18" height="14" rx="2" stroke="currentColor" strokeWidth="2"/>
                <path d="M3 7L12 13L21 7" stroke="currentColor" strokeWidth="2"/>
              </svg>
            </div>
            <h4>Email</h4>
            <p className="card-value">support@taxwranglers.gov</p>
            <p className="card-description">Response within 24 hours</p>
          </div>

          <div className="info-card">
            <div className="card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M12 21C16.9706 21 21 16.9706 21 12C21 7.02944 16.9706 3 12 3C7.02944 3 3 7.02944 3 12C3 16.9706 7.02944 21 12 21Z" stroke="currentColor" strokeWidth="2"/>
                <path d="M12 7V12L15 15" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
              </svg>
            </div>
            <h4>Office Hours</h4>
            <p className="card-value">Mon - Fri: 8:00 - 16:00</p>
            <p className="card-description">Sat: 10:00 - 14:00 • Sun: Closed</p>
          </div>

          <div className="info-card">
            <div className="card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M12 21C15.5 17.4 19 14.1764 19 10.2C19 6.22355 15.866 3 12 3C8.13401 3 5 6.22355 5 10.2C5 14.1764 8.5 17.4 12 21Z" stroke="currentColor" strokeWidth="2"/>
                <circle cx="12" cy="10" r="2" stroke="currentColor" strokeWidth="2"/>
              </svg>
            </div>
            <h4>Visit Us</h4>
            <p className="card-value">123 Government Plaza</p>
            <p className="card-description">Tax Valley, TV 12345</p>
          </div>
        </div>
      </section>

      {/* Services Section */}
      <section className="services-section">
        <div className="section-header">
          <h3>Our Services</h3>
          <p>Comprehensive tax solutions tailored to your needs</p>
        </div>
        
        <div className="services-grid">
          <div className="service-item">
            <div className="service-icon">
              <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
                <rect x="4" y="4" width="24" height="24" rx="2" stroke="currentColor" strokeWidth="2"/>
                <path d="M12 4V28M20 4V28M4 12H28M4 20H28" stroke="currentColor" strokeWidth="2"/>
              </svg>
            </div>
            <h4>Tax Returns</h4>
            <p>Expert assistance with filing your annual tax returns accurately and on time</p>
          </div>
          
          <div className="service-item">
            <div className="service-icon">
              <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
                <circle cx="16" cy="16" r="12" stroke="currentColor" strokeWidth="2"/>
                <path d="M16 8V16L20 20" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
              </svg>
            </div>
            <h4>Tax Planning</h4>
            <p>Strategic planning to optimize your tax situation throughout the year</p>
          </div>
          
          <div className="service-item">
            <div className="service-icon">
              <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
                <path d="M16 4L28 10V22L16 28L4 22V10L16 4Z" stroke="currentColor" strokeWidth="2"/>
                <path d="M10 13L16 16L22 13M16 16V26" stroke="currentColor" strokeWidth="2"/>
              </svg>
            </div>
            <h4>Compliance</h4>
            <p>Ensure your business meets all regulatory requirements and standards</p>
          </div>
          
          <div className="service-item">
            <div className="service-icon">
              <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
                <rect x="6" y="8" width="20" height="16" rx="2" stroke="currentColor" strokeWidth="2"/>
                <path d="M6 14H26M12 8V6M20 8V6" stroke="currentColor" strokeWidth="2"/>
                <circle cx="12" cy="19" r="1.5" fill="currentColor"/>
                <circle cx="16" cy="19" r="1.5" fill="currentColor"/>
                <circle cx="20" cy="19" r="1.5" fill="currentColor"/>
              </svg>
            </div>
            <h4>Consultations</h4>
            <p>One-on-one sessions with tax professionals to address your specific needs</p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="landing-footer">
        <div className="footer-content">
          <div className="footer-section">
            <h4>Tax Wranglers</h4>
            <p>Professional tax services you can trust</p>
          </div>
          <div className="footer-section">
            <h5>Quick Links</h5>
            <ul>
              <li><a href="#services">Services</a></li>
              <li><a href="#contact">Contact</a></li>
              <li><a href="#about">About Us</a></li>
            </ul>
          </div>
          <div className="footer-section">
            <h5>Legal</h5>
            <ul>
              <li><a href="#privacy">Privacy Policy</a></li>
              <li><a href="#terms">Terms of Service</a></li>
              <li><a href="#accessibility">Accessibility</a></li>
            </ul>
          </div>
        </div>
        <div className="footer-bottom">
          <p>© 2025 Tax Wranglers. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default LandingPage;
