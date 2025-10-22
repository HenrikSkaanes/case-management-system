import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { createTicket } from '../services/api';
import './LandingPage.css';

const LandingPage = () => {
  const navigate = useNavigate();
  const [showSubmitForm, setShowSubmitForm] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: '',
    priority: 'medium',
    customer_name: '',
    customer_email: '',
    customer_phone: '',
  });
  const [formErrors, setFormErrors] = useState({});
  const [submitStatus, setSubmitStatus] = useState(null); // 'success' or 'error'
  
  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    if (formErrors[name]) {
      setFormErrors(prev => ({ ...prev, [name]: '' }));
    }
  };
  
  const validateForm = () => {
    const errors = {};
    if (!formData.title.trim()) errors.title = 'Title is required';
    if (!formData.category) errors.category = 'Category is required';
    if (!formData.customer_name.trim()) errors.customer_name = 'Name is required';
    if (!formData.customer_email.trim()) {
      errors.customer_email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.customer_email)) {
      errors.customer_email = 'Invalid email format';
    }
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };
  
  const handleSubmitCase = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;
    
    try {
      await createTicket(formData);
      setSubmitStatus('success');
      setFormData({
        title: '',
        description: '',
        category: '',
        priority: 'medium',
        customer_name: '',
        customer_email: '',
        customer_phone: '',
      });
      setTimeout(() => {
        setShowSubmitForm(false);
        setSubmitStatus(null);
      }, 3000);
    } catch (error) {
      console.error('Error submitting case:', error);
      setSubmitStatus('error');
    }
  };

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

          <div className="info-card submit-case-card">
            <div className="card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M12 4V20M5 12H19" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
              </svg>
            </div>
            <h4>Submit a Case</h4>
            <p className="card-value">Get Help Online</p>
            <button 
              className="submit-case-btn"
              onClick={() => setShowSubmitForm(true)}
            >
              Submit New Case
            </button>
          </div>
        </div>
      </section>

      {/* Case Submission Modal */}
      {showSubmitForm && (
        <div className="modal-overlay" onClick={() => setShowSubmitForm(false)}>
          <div className="modal-content submit-case-modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>📝 Submit a New Case</h2>
              <button className="close-button" onClick={() => setShowSubmitForm(false)}>✕</button>
            </div>

            {submitStatus === 'success' ? (
              <div className="success-message">
                <div className="success-icon">✅</div>
                <h3>Case Submitted Successfully!</h3>
                <p>We've received your case and will get back to you soon.</p>
                <p className="success-detail">Check your email for confirmation.</p>
              </div>
            ) : (
              <form onSubmit={handleSubmitCase} className="submit-case-form">
                <div className="form-section">
                  <h3>📋 Case Details</h3>
                  
                  <div className="form-group">
                    <label htmlFor="title">
                      Issue Title <span className="required">*</span>
                    </label>
                    <input
                      type="text"
                      id="title"
                      name="title"
                      value={formData.title}
                      onChange={handleFormChange}
                      placeholder="Brief description of your issue"
                      className={formErrors.title ? 'error' : ''}
                    />
                    {formErrors.title && <span className="error-message">{formErrors.title}</span>}
                  </div>

                  <div className="form-group">
                    <label htmlFor="description">Description</label>
                    <textarea
                      id="description"
                      name="description"
                      value={formData.description}
                      onChange={handleFormChange}
                      placeholder="Provide detailed information about your issue"
                      rows="4"
                    />
                  </div>

                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="category">
                        Category <span className="required">*</span>
                      </label>
                      <select
                        id="category"
                        name="category"
                        value={formData.category}
                        onChange={handleFormChange}
                        className={formErrors.category ? 'error' : ''}
                      >
                        <option value="">Select category</option>
                        <option value="returns">Tax Returns</option>
                        <option value="vat">VAT Support</option>
                        <option value="deductions">Deductions</option>
                        <option value="compliance">Compliance</option>
                        <option value="other">Other</option>
                      </select>
                      {formErrors.category && <span className="error-message">{formErrors.category}</span>}
                    </div>

                    <div className="form-group">
                      <label htmlFor="priority">Priority</label>
                      <select
                        id="priority"
                        name="priority"
                        value={formData.priority}
                        onChange={handleFormChange}
                      >
                        <option value="low">🟢 Low</option>
                        <option value="medium">🟡 Medium</option>
                        <option value="high">🟠 High</option>
                        <option value="critical">🔴 Critical</option>
                      </select>
                    </div>
                  </div>
                </div>

                <div className="form-section">
                  <h3>👤 Your Information</h3>
                  
                  <div className="form-group">
                    <label htmlFor="customer_name">
                      Full Name <span className="required">*</span>
                    </label>
                    <input
                      type="text"
                      id="customer_name"
                      name="customer_name"
                      value={formData.customer_name}
                      onChange={handleFormChange}
                      placeholder="Your full name"
                      className={formErrors.customer_name ? 'error' : ''}
                    />
                    {formErrors.customer_name && <span className="error-message">{formErrors.customer_name}</span>}
                  </div>

                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="customer_email">
                        Email <span className="required">*</span>
                      </label>
                      <input
                        type="email"
                        id="customer_email"
                        name="customer_email"
                        value={formData.customer_email}
                        onChange={handleFormChange}
                        placeholder="your.email@example.com"
                        className={formErrors.customer_email ? 'error' : ''}
                      />
                      {formErrors.customer_email && <span className="error-message">{formErrors.customer_email}</span>}
                    </div>

                    <div className="form-group">
                      <label htmlFor="customer_phone">Phone</label>
                      <input
                        type="tel"
                        id="customer_phone"
                        name="customer_phone"
                        value={formData.customer_phone}
                        onChange={handleFormChange}
                        placeholder="+47 123 45 678"
                      />
                    </div>
                  </div>
                </div>

                {submitStatus === 'error' && (
                  <div className="error-banner">
                    ⚠️ Failed to submit case. Please try again or contact us directly.
                  </div>
                )}

                <div className="modal-footer">
                  <button type="button" className="btn-cancel" onClick={() => setShowSubmitForm(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn-submit">
                    Submit Case
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

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
