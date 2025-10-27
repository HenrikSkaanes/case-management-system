import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import KanbanColumn from './KanbanColumn'
import TicketModal from './TicketModal'
import PowerBIEmbed from './PowerBIEmbed'
import { fetchTickets, createTicket, updateTicket, deleteTicket, sendResponse } from '../services/api'
import './Dashboard.css'

/**
 * Employee Dashboard - Kanban Board for managing tickets
 */
function Dashboard() {
  const navigate = useNavigate();
  const [tickets, setTickets] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [filterCategory, setFilterCategory] = useState('')
  const [filterPriority, setFilterPriority] = useState('')
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingTicket, setEditingTicket] = useState(null)
  const [activeTab, setActiveTab] = useState('kanban') // 'kanban' or 'metrics'

  useEffect(() => {
    console.log('🔄 Dashboard mounted - loading tickets...');
    loadTickets()
  }, [])

  const loadTickets = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await fetchTickets()
      setTickets(data)
    } catch (err) {
      setError('Failed to load tickets. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateTicket = async (ticketData) => {
    try {
      const newTicket = await createTicket(ticketData)
      setTickets(prev => [newTicket, ...prev])
    } catch (err) {
      alert('Failed to create ticket')
      console.error(err)
    }
  }

  const handleUpdateTicket = async (ticketId, updates) => {
    try {
      const updatedTicket = await updateTicket(ticketId, updates)
      setTickets(prev =>
        prev.map(ticket => (ticket.id === ticketId ? updatedTicket : ticket))
      )
    } catch (err) {
      alert('Failed to update ticket')
      console.error(err)
    }
  }

  const handleDeleteTicket = async (ticketId) => {
    try {
      await deleteTicket(ticketId)
      setTickets(prev => prev.filter(ticket => ticket.id !== ticketId))
    } catch (err) {
      alert('Failed to delete ticket')
      console.error(err)
    }
  }

  const handleEditTicket = (ticket) => {
    setEditingTicket(ticket)
    setIsModalOpen(true)
  }

  const handleModalSubmit = async (formData) => {
    if (editingTicket) {
      await handleUpdateTicket(editingTicket.id, formData)
    } else {
      await handleCreateTicket(formData)
    }
    setEditingTicket(null)
  }

  const handleModalClose = () => {
    setIsModalOpen(false)
    setEditingTicket(null)
  }

  const handleRespond = async (ticketId, responseData) => {
    try {
      // Call the backend API to send email via Azure Communication Services
      const response = await sendResponse(ticketId, responseData);
      
      console.log('✅ Email sent successfully:', response);
      
      // Reload tickets to get updated first_response_at timestamp
      await loadTickets();
      
      return response;
    } catch (error) {
      console.error('❌ Failed to send email:', error);
      throw error; // Re-throw so TicketCard can show error message
    }
  }

  const filteredTickets = tickets.filter(ticket => {
    const matchesSearch = ticket.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         ticket.description?.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesCategory = !filterCategory || ticket.category === filterCategory
    const matchesPriority = !filterPriority || ticket.priority === filterPriority
    return matchesSearch && matchesCategory && matchesPriority
  })

  const ticketsByStatus = {
    new: filteredTickets.filter(t => t.status === 'new'),
    in_progress: filteredTickets.filter(t => t.status === 'in_progress'),
    resolved: filteredTickets.filter(t => t.status === 'resolved' || t.status === 'closed'),
  }

  const categories = [...new Set(tickets.map(t => t.category))].filter(Boolean).sort()
  
  // Metrics calculations
  const priorityCounts = {
    low: tickets.filter(t => t.priority === 'low').length,
    medium: tickets.filter(t => t.priority === 'medium').length,
    high: tickets.filter(t => t.priority === 'high').length,
    critical: tickets.filter(t => t.priority === 'critical').length,
  }
  
  // Average resolution time (if we have resolved tickets with resolution_time_minutes)
  const resolvedTicketsWithTime = tickets.filter(t => 
    (t.status === 'resolved' || t.status === 'closed') && t.resolution_time_minutes
  )
  const avgResolutionTime = resolvedTicketsWithTime.length > 0
    ? Math.round(resolvedTicketsWithTime.reduce((sum, t) => sum + t.resolution_time_minutes, 0) / resolvedTicketsWithTime.length)
    : 0
  
  // Tickets created per day (last 7 days)
  const last7Days = Array.from({length: 7}, (_, i) => {
    const date = new Date()
    date.setDate(date.getDate() - (6 - i))
    return date.toISOString().split('T')[0]
  })
  
  const ticketsPerDay = last7Days.map(day => {
    return tickets.filter(t => t.created_at?.startsWith(day)).length
  })

  if (loading) {
    return (
      <div className="dashboard">
        <div className="loading-container">
          <div className="spinner"></div>
          <p>Loading tickets...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="dashboard">
        <div className="error-container">
          <h2>⚠️ Error</h2>
          <p>{error}</p>
          <button onClick={loadTickets} className="btn-retry">Retry</button>
        </div>
      </div>
    )
  }

  return (
    <div className="dashboard">
      <header className="app-header">
        <div className="header-content">
          <div className="header-left">
            <button 
              className="btn-home"
              onClick={() => navigate('/')}
              title="Back to home"
            >
              ← Home
            </button>
            <h1>📋 Tax Wranglers - Employee Dashboard</h1>
            <p className="subtitle">Case Management & Ticketing System</p>
          </div>
          <button 
            className="btn-create"
            onClick={() => setIsModalOpen(true)}
          >
            ➕ New Ticket
          </button>
        </div>

        <div className="tabs">
          <button 
            className={`tab ${activeTab === 'kanban' ? 'active' : ''}`}
            onClick={() => setActiveTab('kanban')}
          >
            📋 Kanban Board
          </button>
          <button 
            className={`tab ${activeTab === 'metrics' ? 'active' : ''}`}
            onClick={() => setActiveTab('metrics')}
          >
            📊 Metrics & KPIs
          </button>
        </div>

        <div className="toolbar">
          <div className="search-box">
            <span className="search-icon">🔍</span>
            <input
              type="text"
              placeholder="Search tickets..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <select
            value={filterCategory}
            onChange={(e) => setFilterCategory(e.target.value)}
            className="filter-select"
          >
            <option value="">All Categories</option>
            {categories.map(cat => (
              <option key={cat} value={cat}>{cat}</option>
            ))}
          </select>

          <select
            value={filterPriority}
            onChange={(e) => setFilterPriority(e.target.value)}
            className="filter-select"
          >
            <option value="">All Priorities</option>
            <option value="low">🟢 Low</option>
            <option value="medium">🟡 Medium</option>
            <option value="high">🔴 High</option>
          </select>

          <button onClick={loadTickets} className="btn-refresh" title="Refresh">
            🔄
          </button>
        </div>

        <div className="stats-bar">
          <div className="stat">
            <span className="stat-value">{tickets.length}</span>
            <span className="stat-label">Total Tickets</span>
          </div>
          <div className="stat">
            <span className="stat-value">{ticketsByStatus.new.length}</span>
            <span className="stat-label">New</span>
          </div>
          <div className="stat">
            <span className="stat-value">{ticketsByStatus.in_progress.length}</span>
            <span className="stat-label">In Progress</span>
          </div>
          <div className="stat">
            <span className="stat-value">{ticketsByStatus.resolved.length}</span>
            <span className="stat-label">Resolved</span>
          </div>
        </div>
      </header>

      {activeTab === 'kanban' ? (
        <main className="kanban-board">
          <KanbanColumn
            status="new"
            title="New"
            icon="📥"
            tickets={ticketsByStatus.new}
            onUpdateTicket={handleUpdateTicket}
            onEditTicket={handleEditTicket}
            onDeleteTicket={handleDeleteTicket}
            onRespond={handleRespond}
          />
          <KanbanColumn
            status="in_progress"
            title="In Progress"
            icon="⚙️"
            tickets={ticketsByStatus.in_progress}
            onUpdateTicket={handleUpdateTicket}
            onEditTicket={handleEditTicket}
            onDeleteTicket={handleDeleteTicket}
            onRespond={handleRespond}
          />
          <KanbanColumn
            status="resolved"
            title="Resolved"
            icon="✅"
            tickets={ticketsByStatus.resolved}
            onUpdateTicket={handleUpdateTicket}
            onEditTicket={handleEditTicket}
            onDeleteTicket={handleDeleteTicket}
            onRespond={handleRespond}
          />
        </main>
      ) : (
        <main className="metrics-view">
          <div className="powerbi-section">
            <div className="section-intro">
              <h2>📊 Analytics & Insights</h2>
              <p>Click on any card below to load and view the corresponding Power BI report. Configure your Power BI reports in the component to display live data.</p>
            </div>

            <div className="powerbi-grid">
              <PowerBIEmbed
                title="Case Volume Analysis"
                description="Track case volumes over time, identify trends, and analyze peak periods"
                icon="📈"
                reportUrl="" // Add your Power BI report URL here
              />

              <PowerBIEmbed
                title="Priority Distribution"
                description="View distribution of cases by priority level and monitor critical cases"
                icon="🎯"
                reportUrl="" // Add your Power BI report URL here
              />

              <PowerBIEmbed
                title="Resolution Time Metrics"
                description="Analyze average resolution times, SLA performance, and response efficiency"
                icon="⏱️"
                reportUrl="" // Add your Power BI report URL here
              />

              <PowerBIEmbed
                title="Customer Satisfaction"
                description="Monitor satisfaction ratings, feedback trends, and service quality metrics"
                icon="⭐"
                reportUrl="" // Add your Power BI report URL here
              />

              <PowerBIEmbed
                title="Department Performance"
                description="Compare performance across departments and identify areas for improvement"
                icon="🏢"
                reportUrl="" // Add your Power BI report URL here
              />

              <PowerBIEmbed
                title="Category Breakdown"
                description="Analyze cases by category to understand common issues and allocate resources"
                icon="📁"
                reportUrl="" // Add your Power BI report URL here
              />
            </div>

            <div className="quick-stats-banner">
              <div className="quick-stat">
                <div className="stat-icon">📊</div>
                <div className="stat-content">
                  <div className="stat-value">{tickets.length}</div>
                  <div className="stat-label">Total Cases</div>
                </div>
              </div>
              <div className="quick-stat">
                <div className="stat-icon">🆕</div>
                <div className="stat-content">
                  <div className="stat-value">{ticketsByStatus.new.length}</div>
                  <div className="stat-label">New Cases</div>
                </div>
              </div>
              <div className="quick-stat">
                <div className="stat-icon">⚙️</div>
                <div className="stat-content">
                  <div className="stat-value">{ticketsByStatus.in_progress.length}</div>
                  <div className="stat-label">In Progress</div>
                </div>
              </div>
              <div className="quick-stat">
                <div className="stat-icon">✅</div>
                <div className="stat-content">
                  <div className="stat-value">{ticketsByStatus.resolved.length}</div>
                  <div className="stat-label">Resolved</div>
                </div>
              </div>
              <div className="quick-stat">
                <div className="stat-icon">📈</div>
                <div className="stat-content">
                  <div className="stat-value">{tickets.length > 0 ? Math.round((ticketsByStatus.resolved.length / tickets.length) * 100) : 0}%</div>
                  <div className="stat-label">Resolution Rate</div>
                </div>
              </div>
            </div>
          </div>
        </main>
      )}

      <TicketModal
        isOpen={isModalOpen}
        onClose={handleModalClose}
        onSubmit={handleModalSubmit}
        ticket={editingTicket}
      />
    </div>
  )
}

export default Dashboard
