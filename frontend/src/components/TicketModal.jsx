import { useState, useEffect } from 'react';
import './TicketModal.css';

/**
 * TicketModal - Modal dialog for creating or editing tickets
 * 
 * Professional form with validation
 */
const TicketModal = ({ isOpen, onClose, onSubmit, ticket = null }) => {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: '',
    priority: 'medium',
    customer_name: '',
    customer_email: '',
    customer_phone: '',
  });

  const [errors, setErrors] = useState({});

  useEffect(() => {
    if (ticket) {
      setFormData({
        title: ticket.title || '',
        description: ticket.description || '',
        category: ticket.category || '',
        priority: ticket.priority || 'medium',
        customer_name: ticket.customer_name || '',
        customer_email: ticket.customer_email || '',
        customer_phone: ticket.customer_phone || '',
      });
    } else {
      setFormData({
        title: '',
        description: '',
        category: '',
        priority: 'medium',
        customer_name: '',
        customer_email: '',
        customer_phone: '',
      });
    }
    setErrors({});
  }, [ticket, isOpen]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    // Clear error for this field
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const validate = () => {
    const newErrors = {};
    
    if (!formData.title.trim()) {
      newErrors.title = 'Title is required';
    }
    
    if (!formData.category.trim()) {
      newErrors.category = 'Category is required';
    }
    
    if (!formData.customer_name.trim()) {
      newErrors.customer_name = 'Customer name is required';
    }
    
    if (!formData.customer_email.trim()) {
      newErrors.customer_email = 'Customer email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.customer_email)) {
      newErrors.customer_email = 'Invalid email format';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (validate()) {
      onSubmit(formData);
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{ticket ? '✏️ Edit Ticket' : '➕ Create New Ticket'}</h2>
          <button className="close-button" onClick={onClose}>✕</button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="title">
              Title <span className="required">*</span>
            </label>
            <input
              type="text"
              id="title"
              name="title"
              value={formData.title}
              onChange={handleChange}
              placeholder="Enter ticket title"
              className={errors.title ? 'error' : ''}
            />
            {errors.title && <span className="error-message">{errors.title}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="description">Description</label>
            <textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleChange}
              placeholder="Enter detailed description (optional)"
              rows="4"
            />
          </div>

          <div className="form-section-title">📋 Ticket Details</div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="category">
                Category <span className="required">*</span>
              </label>
              <select
                id="category"
                name="category"
                value={formData.category}
                onChange={handleChange}
                className={errors.category ? 'error' : ''}
              >
                <option value="">Select category</option>
                <option value="returns">Tax Returns</option>
                <option value="vat">VAT Support</option>
                <option value="deductions">Deductions</option>
                <option value="compliance">Compliance</option>
                <option value="other">Other</option>
              </select>
              {errors.category && <span className="error-message">{errors.category}</span>}
            </div>

            <div className="form-group">
              <label htmlFor="priority">Priority</label>
              <select
                id="priority"
                name="priority"
                value={formData.priority}
                onChange={handleChange}
              >
                <option value="low">🟢 Low</option>
                <option value="medium">🟡 Medium</option>
                <option value="high">� High</option>
                <option value="critical">�🔴 Critical</option>
              </select>
            </div>
          </div>

          <div className="form-section-title">👤 Customer Information</div>

          <div className="form-group">
            <label htmlFor="customer_name">
              Customer Name <span className="required">*</span>
            </label>
            <input
              type="text"
              id="customer_name"
              name="customer_name"
              value={formData.customer_name}
              onChange={handleChange}
              placeholder="Enter customer full name"
              className={errors.customer_name ? 'error' : ''}
            />
            {errors.customer_name && <span className="error-message">{errors.customer_name}</span>}
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
                onChange={handleChange}
                placeholder="customer@example.com"
                className={errors.customer_email ? 'error' : ''}
              />
              {errors.customer_email && <span className="error-message">{errors.customer_email}</span>}
            </div>

            <div className="form-group">
              <label htmlFor="customer_phone">Phone</label>
              <input
                type="tel"
                id="customer_phone"
                name="customer_phone"
                value={formData.customer_phone}
                onChange={handleChange}
                placeholder="+47 123 45 678"
              />
            </div>
          </div>

          <div className="modal-footer">
            <button type="button" className="btn-cancel" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn-submit">
              {ticket ? 'Update Ticket' : 'Create Ticket'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default TicketModal;
