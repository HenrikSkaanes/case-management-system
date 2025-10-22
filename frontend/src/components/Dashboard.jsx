import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import KanbanColumn from './KanbanColumn'
import TicketModal from './TicketModal'
import { fetchTickets, createTicket, updateTicket, deleteTicket } from '../services/api'
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
          />
          <KanbanColumn
            status="in_progress"
            title="In Progress"
            icon="⚙️"
            tickets={ticketsByStatus.in_progress}
            onUpdateTicket={handleUpdateTicket}
            onEditTicket={handleEditTicket}
            onDeleteTicket={handleDeleteTicket}
          />
          <KanbanColumn
            status="resolved"
            title="Resolved"
            icon="✅"
            tickets={ticketsByStatus.resolved}
            onUpdateTicket={handleUpdateTicket}
            onEditTicket={handleEditTicket}
            onDeleteTicket={handleDeleteTicket}
          />
        </main>
      ) : (
        <main className="metrics-view">
          <div className="metrics-grid">
            
            {/* Priority Distribution */}
            <div className="metric-card">
              <h3>📊 Cases by Priority</h3>
              <div className="priority-chart">
                <div className="priority-bar">
                  <div className="priority-label">
                    <span className="priority-icon critical">🔴</span>
                    <span>Critical</span>
                  </div>
                  <div className="bar-container">
                    <div 
                      className="bar critical" 
                      style={{width: `${tickets.length > 0 ? (priorityCounts.critical / tickets.length) * 100 : 0}%`}}
                    ></div>
                    <span className="bar-value">{priorityCounts.critical}</span>
                  </div>
                </div>
                <div className="priority-bar">
                  <div className="priority-label">
                    <span className="priority-icon high">🟠</span>
                    <span>High</span>
                  </div>
                  <div className="bar-container">
                    <div 
                      className="bar high" 
                      style={{width: `${tickets.length > 0 ? (priorityCounts.high / tickets.length) * 100 : 0}%`}}
                    ></div>
                    <span className="bar-value">{priorityCounts.high}</span>
                  </div>
                </div>
                <div className="priority-bar">
                  <div className="priority-label">
                    <span className="priority-icon medium">🟡</span>
                    <span>Medium</span>
                  </div>
                  <div className="bar-container">
                    <div 
                      className="bar medium" 
                      style={{width: `${tickets.length > 0 ? (priorityCounts.medium / tickets.length) * 100 : 0}%`}}
                    ></div>
                    <span className="bar-value">{priorityCounts.medium}</span>
                  </div>
                </div>
                <div className="priority-bar">
                  <div className="priority-label">
                    <span className="priority-icon low">🟢</span>
                    <span>Low</span>
                  </div>
                  <div className="bar-container">
                    <div 
                      className="bar low" 
                      style={{width: `${tickets.length > 0 ? (priorityCounts.low / tickets.length) * 100 : 0}%`}}
                    ></div>
                    <span className="bar-value">{priorityCounts.low}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Cases Trend (Last 7 Days) */}
            <div className="metric-card">
              <h3>📈 New Cases (Last 7 Days)</h3>
              <div className="line-chart">
                {last7Days.map((day, index) => (
                  <div key={day} className="chart-bar-wrapper">
                    <div className="chart-bar-container">
                      <div 
                        className="chart-bar"
                        style={{
                          height: `${Math.max(...ticketsPerDay) > 0 ? (ticketsPerDay[index] / Math.max(...ticketsPerDay)) * 100 : 0}%`
                        }}
                      >
                        <span className="bar-label">{ticketsPerDay[index]}</span>
                      </div>
                    </div>
                    <div className="chart-x-label">
                      {new Date(day).toLocaleDateString('en-US', {weekday: 'short'})}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Key Metrics */}
            <div className="metric-card">
              <h3>⚡ Key Performance Indicators</h3>
              <div className="kpi-list">
                <div className="kpi-item">
                  <div className="kpi-label">Average Resolution Time</div>
                  <div className="kpi-value">
                    {avgResolutionTime > 0 ? `${Math.floor(avgResolutionTime / 60)}h ${avgResolutionTime % 60}m` : 'N/A'}
                  </div>
                </div>
                <div className="kpi-item">
                  <div className="kpi-label">Open Cases</div>
                  <div className="kpi-value">{ticketsByStatus.new.length + ticketsByStatus.in_progress.length}</div>
                </div>
                <div className="kpi-item">
                  <div className="kpi-label">Resolution Rate</div>
                  <div className="kpi-value">
                    {tickets.length > 0 ? Math.round((ticketsByStatus.resolved.length / tickets.length) * 100) : 0}%
                  </div>
                </div>
                <div className="kpi-item">
                  <div className="kpi-label">Total Cases</div>
                  <div className="kpi-value">{tickets.length}</div>
                </div>
              </div>
            </div>

            {/* Category Breakdown */}
            <div className="metric-card">
              <h3>📁 Cases by Category</h3>
              <div className="category-list">
                {categories.map(category => {
                  const count = tickets.filter(t => t.category === category).length
                  const percentage = tickets.length > 0 ? (count / tickets.length) * 100 : 0
                  return (
                    <div key={category} className="category-item">
                      <div className="category-header">
                        <span className="category-name">{category}</span>
                        <span className="category-count">{count}</span>
                      </div>
                      <div className="category-bar-bg">
                        <div 
                          className="category-bar-fill" 
                          style={{width: `${percentage}%`}}
                        ></div>
                      </div>
                    </div>
                  )
                })}
                {categories.length === 0 && (
                  <p className="no-data">No categories yet</p>
                )}
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
