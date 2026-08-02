using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Runtime.InteropServices;
using System.Text;

namespace Hermes.Data.SQLite
{
    /// <summary>
    /// Minimal ADO.NET provider wrapping winsqlite3.dll (built-in Windows SQLite).
    /// </summary>
    public sealed class HermesSQLiteFactory : DbProviderFactory
    {
        public static readonly HermesSQLiteFactory Instance = new HermesSQLiteFactory();
        public override DbConnection CreateConnection() { return new HermesSQLiteConnection(); }
        public override DbCommand CreateCommand() { return new HermesSQLiteCommand(); }
        public override DbParameter CreateParameter() { return new HermesSQLiteParameter(); }
        public override DbDataAdapter CreateDataAdapter() { return new HermesSQLiteDataAdapter(); }
    }

    public sealed class HermesSQLiteConnection : DbConnection
    {
        private string _connectionString;
        private ConnectionState _state = ConnectionState.Closed;
        private IntPtr _dbHandle = IntPtr.Zero;
        private string _dataSource;

        public override string ConnectionString
        {
            get
            {
                if (_connectionString == null) return "Data Source=:memory:";
                return _connectionString;
            }
            set
            {
                _connectionString = value;
                ParseConnectionString(value);
            }
        }

        public override string Database
        {
            get
            {
                if (_dataSource == null) return ":memory:";
                return _dataSource;
            }
        }

        public override string DataSource
        {
            get
            {
                if (_dataSource == null) return ":memory:";
                return _dataSource;
            }
        }

        public override string ServerVersion { get { return "3.45.3"; } }
        public override ConnectionState State { get { return _state; } }
        internal IntPtr DbHandle { get { return _dbHandle; } }

        public HermesSQLiteConnection() { }
        public HermesSQLiteConnection(string connectionString) { ConnectionString = connectionString; }

        private void ParseConnectionString(string cs)
        {
            if (string.IsNullOrEmpty(cs)) return;
            foreach (string part in cs.Split(';'))
            {
                string[] kv = part.Split('=');
                if (kv.Length == 2 && kv[0].Trim().Equals("Data Source", StringComparison.OrdinalIgnoreCase))
                {
                    _dataSource = kv[1].Trim().Trim('"');
                    break;
                }
            }
        }

        public override void Open()
        {
            if (_state == ConnectionState.Open) return;
            string dbPath = _dataSource;
            if (dbPath == null) dbPath = ":memory:";
            IntPtr handle;
            int rc = NativeMethods.sqlite3_open(dbPath, out handle);
            if (rc != 0)
            {
                string errMsg = GetLastErrorMsg(handle);
                throw new InvalidOperationException("SQLite open failed (" + rc + "): " + (errMsg ?? "Unknown error"));
            }
            _dbHandle = handle;
            _state = ConnectionState.Open;
        }

        public override void Close()
        {
            if (_dbHandle != IntPtr.Zero)
            {
                NativeMethods.sqlite3_close(_dbHandle);
                _dbHandle = IntPtr.Zero;
            }
            _state = ConnectionState.Closed;
        }

        protected override DbTransaction BeginDbTransaction(IsolationLevel isolationLevel)
        {
            return new HermesSQLiteTransaction(this, isolationLevel);
        }

        protected override DbCommand CreateDbCommand()
        {
            HermesSQLiteCommand cmd = new HermesSQLiteCommand();
            cmd.Connection = this;
            return cmd;
        }

        private string GetLastErrorMsg(IntPtr db)
        {
            if (db == IntPtr.Zero) return "Unknown error";
            IntPtr p = NativeMethods.sqlite3_errmsg(db);
            if (p != IntPtr.Zero) return Marshal.PtrToStringAnsi(p);
            return "Unknown error";
        }

        public override void ChangeDatabase(string databaseName)
        {
            throw new NotSupportedException("SQLite does not support ChangeDatabase.");
        }

        internal void CheckOpen()
        {
            if (_state != ConnectionState.Open || _dbHandle == IntPtr.Zero)
                throw new InvalidOperationException("Connection is not open.");
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) Close();
            base.Dispose(disposing);
        }
    }

    public sealed class HermesSQLiteCommand : DbCommand
    {
        private HermesSQLiteConnection _connection;
        private string _commandText;
        private HermesSQLiteTransaction _transaction;

        public override string CommandText
        {
            get
            {
                if (_commandText == null) return "";
                return _commandText;
            }
            set { _commandText = value; }
        }

        public override int CommandTimeout { get; set; }
        public override CommandType CommandType { get; set; }
        public override UpdateRowSource UpdatedRowSource { get; set; }
        public override bool DesignTimeVisible { get; set; }

        protected override DbConnection DbConnection
        {
            get { return _connection; }
            set { _connection = (HermesSQLiteConnection)value; }
        }

        public new HermesSQLiteConnection Connection
        {
            get { return _connection; }
            set { _connection = value; }
        }

        protected override DbTransaction DbTransaction
        {
            get { return _transaction; }
            set { _transaction = (HermesSQLiteTransaction)value; }
        }

        public new HermesSQLiteParameterCollection Parameters { get; private set; }

        public HermesSQLiteCommand()
        {
            Parameters = new HermesSQLiteParameterCollection();
        }

        public override void Cancel() { }

        public override int ExecuteNonQuery()
        {
            _connection.CheckOpen();
            IntPtr stmt;
            int rc = NativeMethods.sqlite3_prepare_v2(_connection.DbHandle, _commandText, out stmt);
            if (rc != 0) throw CreateException(rc);
            try
            {
                BindParameters(stmt);
                rc = NativeMethods.sqlite3_step(stmt);
                if (rc != 101 && rc != 100) // SQLITE_DONE=101, SQLITE_ROW=100
                    throw CreateException(rc);
                return NativeMethods.sqlite3_changes(_connection.DbHandle);
            }
            finally
            {
                NativeMethods.sqlite3_finalize(stmt);
            }
        }

        public override object ExecuteScalar()
        {
            _connection.CheckOpen();
            IntPtr stmt;
            int rc = NativeMethods.sqlite3_prepare_v2(_connection.DbHandle, _commandText, out stmt);
            if (rc != 0) throw CreateException(rc);
            try
            {
                BindParameters(stmt);
                rc = NativeMethods.sqlite3_step(stmt);
                if (rc == 100) // SQLITE_ROW
                {
                    if (NativeMethods.sqlite3_column_type(stmt, 0) == 5) return null; // SQLITE_NULL
                    IntPtr p = NativeMethods.sqlite3_column_text(stmt, 0);
                    if (p != IntPtr.Zero) return Marshal.PtrToStringAnsi(p);
                    return null;
                }
                return null;
            }
            finally
            {
                NativeMethods.sqlite3_finalize(stmt);
            }
        }

        protected override DbDataReader ExecuteDbDataReader(CommandBehavior behavior)
        {
            _connection.CheckOpen();
            IntPtr stmt;
            int rc = NativeMethods.sqlite3_prepare_v2(_connection.DbHandle, _commandText, out stmt);
            if (rc != 0) throw CreateException(rc);
            BindParameters(stmt);
            return new HermesSQLiteDataReader(stmt, _connection);
        }

        private void BindParameters(IntPtr stmt)
        {
            foreach (HermesSQLiteParameter p in Parameters)
            {
                int idx = NativeMethods.sqlite3_bind_parameter_index(stmt, p.ParameterName);
                if (idx == 0) continue;
                if (p.Value == null || p.Value == DBNull.Value)
                    NativeMethods.sqlite3_bind_null(stmt, idx);
                else if (p.Value is int)
                    NativeMethods.sqlite3_bind_int(stmt, idx, (int)p.Value);
                else if (p.Value is long)
                    NativeMethods.sqlite3_bind_int64(stmt, idx, (long)p.Value);
                else if (p.Value is double)
                    NativeMethods.sqlite3_bind_double(stmt, idx, (double)p.Value);
                else if (p.Value is byte[])
                    NativeMethods.sqlite3_bind_blob(stmt, idx, (byte[])p.Value, ((byte[])p.Value).Length);
                else
                    NativeMethods.sqlite3_bind_text(stmt, idx, p.Value.ToString());
            }
        }

        private Exception CreateException(int rc)
        {
            string msg = "Unknown error";
            if (_connection != null && _connection.DbHandle != IntPtr.Zero)
            {
                IntPtr p = NativeMethods.sqlite3_errmsg(_connection.DbHandle);
                if (p != IntPtr.Zero) msg = Marshal.PtrToStringAnsi(p);
            }
            return new InvalidOperationException("SQLite error (" + rc + "): " + msg);
        }

        public override void Prepare() { }

        protected override DbParameter CreateDbParameter()
        {
            return new HermesSQLiteParameter();
        }

        protected override DbParameterCollection DbParameterCollection
        {
            get { return Parameters; }
        }
    }

    public sealed class HermesSQLiteParameter : DbParameter
    {
        public override string ParameterName { get; set; }
        public override object Value { get; set; }
        public override DbType DbType { get; set; }
        public override ParameterDirection Direction { get; set; }
        public override bool IsNullable { get; set; }
        public override string SourceColumn { get; set; }
        public override bool SourceColumnNullMapping { get; set; }
        public override int Size { get; set; }
        public override DataRowVersion SourceVersion { get; set; }

        public HermesSQLiteParameter()
        {
            DbType = DbType.String;
            Direction = ParameterDirection.Input;
            IsNullable = true;
        }

        public override void ResetDbType()
        {
            DbType = DbType.String;
        }
    }

    public sealed class HermesSQLiteParameterCollection : DbParameterCollection, System.Collections.IEnumerable
    {
        private readonly List<HermesSQLiteParameter> _list = new List<HermesSQLiteParameter>();

        public override int Count { get { return _list.Count; } }
        public override object SyncRoot { get { return ((System.Collections.ICollection)_list).SyncRoot; } }

        public HermesSQLiteParameter Add(HermesSQLiteParameter p)
        {
            _list.Add(p);
            return p;
        }

        public HermesSQLiteParameter AddWithValue(string name, object value)
        {
            HermesSQLiteParameter p = new HermesSQLiteParameter();
            p.ParameterName = name;
            p.Value = value;
            _list.Add(p);
            return p;
        }

        public override void AddRange(Array values)
        {
            foreach (object v in values)
                Add(v);
        }

        public override int Add(object value)
        {
            _list.Add((HermesSQLiteParameter)value);
            return _list.Count - 1;
        }

        public override bool Contains(object value)
        {
            return _list.Contains((HermesSQLiteParameter)value);
        }

        public override bool Contains(string value)
        {
            return _list.Exists(p => p.ParameterName == value);
        }

        public override void CopyTo(Array array, int index)
        {
            ((System.Collections.ICollection)_list).CopyTo(array, index);
        }

        public override int IndexOf(object value)
        {
            return _list.IndexOf((HermesSQLiteParameter)value);
        }

        public override int IndexOf(string parameterName)
        {
            return _list.FindIndex(p => p.ParameterName == parameterName);
        }

        public override void Insert(int index, object value)
        {
            _list.Insert(index, (HermesSQLiteParameter)value);
        }

        public override void Remove(object value)
        {
            _list.Remove((HermesSQLiteParameter)value);
        }

        public override void RemoveAt(int index)
        {
            _list.RemoveAt(index);
        }

        public override void RemoveAt(string parameterName)
        {
            _list.RemoveAll(p => p.ParameterName == parameterName);
        }

        public override void Clear()
        {
            _list.Clear();
        }

        public override bool IsFixedSize { get { return false; } }
        public override bool IsReadOnly { get { return false; } }
        public override bool IsSynchronized { get { return false; } }

        protected override DbParameter GetParameter(int index)
        {
            return _list[index];
        }

        protected override DbParameter GetParameter(string parameterName)
        {
            return _list.Find(p => p.ParameterName == parameterName);
        }

        protected override void SetParameter(int index, DbParameter value)
        {
            _list[index] = (HermesSQLiteParameter)value;
        }

        protected override void SetParameter(string parameterName, DbParameter value)
        {
            int i = _list.FindIndex(p => p.ParameterName == parameterName);
            if (i >= 0) _list[i] = (HermesSQLiteParameter)value;
        }

        public override System.Collections.IEnumerator GetEnumerator()
        {
            return _list.GetEnumerator();
        }
    }

    public sealed class HermesSQLiteTransaction : DbTransaction
    {
        private HermesSQLiteConnection _connection;
        private bool _disposed = false;
        private IsolationLevel _isolationLevel;

        public override IsolationLevel IsolationLevel { get { return _isolationLevel; } }
        protected override DbConnection DbConnection { get { return _connection; } }

        public HermesSQLiteTransaction(HermesSQLiteConnection conn, IsolationLevel isolationLevel)
        {
            _connection = conn;
            _isolationLevel = isolationLevel;
            using (HermesSQLiteCommand cmd = new HermesSQLiteCommand())
            {
                cmd.Connection = conn;
                cmd.CommandText = "BEGIN TRANSACTION;";
                cmd.ExecuteNonQuery();
            }
        }

        public override void Commit()
        {
            if (_disposed) throw new ObjectDisposedException("HermesSQLiteTransaction");
            using (HermesSQLiteCommand cmd = new HermesSQLiteCommand())
            {
                cmd.Connection = _connection;
                cmd.CommandText = "COMMIT;";
                cmd.ExecuteNonQuery();
            }
            _disposed = true;
        }

        public override void Rollback()
        {
            if (_disposed) return;
            using (HermesSQLiteCommand cmd = new HermesSQLiteCommand())
            {
                cmd.Connection = _connection;
                cmd.CommandText = "ROLLBACK;";
                cmd.ExecuteNonQuery();
            }
            _disposed = true;
        }

        protected override void Dispose(bool disposing)
        {
            if (!_disposed && disposing) Rollback();
            base.Dispose(disposing);
        }
    }

    public sealed class HermesSQLiteDataReader : DbDataReader
    {
        private readonly IntPtr _stmt;
        private bool _closed = false;
        private int _recordsAffected = -1;

        public override int Depth { get { return 0; } }
        public override bool IsClosed { get { return _closed; } }
        public override int RecordsAffected { get { return _recordsAffected; } }

        public override int FieldCount
        {
            get
            {
                if (_closed) return 0;
                return NativeMethods.sqlite3_column_count(_stmt);
            }
        }

        public override bool HasRows
        {
            get { throw new NotImplementedException(); }
        }

        public override object this[int ordinal]
        {
            get { return GetValue(ordinal); }
        }

        public override object this[string name]
        {
            get { return GetValue(GetOrdinal(name)); }
        }

        public HermesSQLiteDataReader(IntPtr stmt, HermesSQLiteConnection connection)
        {
            _stmt = stmt;
        }

        public override bool Read()
        {
            if (_closed) return false;
            int rc = NativeMethods.sqlite3_step(_stmt);
            if (rc == 100) return true; // SQLITE_ROW
            return false;
        }

        public override bool NextResult() { return false; }

        public override void Close()
        {
            if (!_closed)
            {
                NativeMethods.sqlite3_finalize(_stmt);
                _closed = true;
            }
        }

        public override string GetName(int ordinal)
        {
            IntPtr p = NativeMethods.sqlite3_column_name(_stmt, ordinal);
            if (p != IntPtr.Zero) return Marshal.PtrToStringAnsi(p);
            return "";
        }

        public override int GetOrdinal(string name)
        {
            for (int i = 0; i < FieldCount; i++)
            {
                if (string.Equals(GetName(i), name, StringComparison.OrdinalIgnoreCase))
                    return i;
            }
            throw new IndexOutOfRangeException("Column '" + name + "' not found.");
        }

        public override Type GetFieldType(int ordinal)
        {
            return typeof(string);
        }

        public override object GetValue(int ordinal)
        {
            int type = NativeMethods.sqlite3_column_type(_stmt, ordinal);
            if (type == 5) return DBNull.Value; // SQLITE_NULL
            if (type == 1) return NativeMethods.sqlite3_column_int64(_stmt, ordinal); // SQLITE_INTEGER
            if (type == 2) return NativeMethods.sqlite3_column_double(_stmt, ordinal); // SQLITE_FLOAT
            IntPtr p = NativeMethods.sqlite3_column_text(_stmt, ordinal);
            if (p != IntPtr.Zero) return Marshal.PtrToStringAnsi(p);
            return "";
        }

        public override bool IsDBNull(int ordinal)
        {
            return NativeMethods.sqlite3_column_type(_stmt, ordinal) == 5;
        }

        public override int GetInt32(int ordinal)
        {
            return (int)GetInt64(ordinal);
        }

        public override long GetInt64(int ordinal)
        {
            return NativeMethods.sqlite3_column_int64(_stmt, ordinal);
        }

        public override double GetDouble(int ordinal)
        {
            return NativeMethods.sqlite3_column_double(_stmt, ordinal);
        }

        public override string GetString(int ordinal)
        {
            IntPtr p = NativeMethods.sqlite3_column_text(_stmt, ordinal);
            if (p != IntPtr.Zero) return Marshal.PtrToStringAnsi(p);
            return "";
        }

        public override bool GetBoolean(int ordinal)
        {
            return GetInt32(ordinal) != 0;
        }

        public override Guid GetGuid(int ordinal)
        {
            return Guid.Parse(GetString(ordinal));
        }

        public override DateTime GetDateTime(int ordinal)
        {
            return DateTime.Parse(GetString(ordinal));
        }

        public override decimal GetDecimal(int ordinal)
        {
            return Convert.ToDecimal(GetDouble(ordinal));
        }

        public override float GetFloat(int ordinal)
        {
            return (float)GetDouble(ordinal);
        }

        public override short GetInt16(int ordinal)
        {
            return (short)GetInt64(ordinal);
        }

        public override byte GetByte(int ordinal)
        {
            return (byte)GetInt64(ordinal);
        }

        public override long GetBytes(int ordinal, long dataOffset, byte[] buffer, int bufferOffset, int length)
        {
            return 0;
        }

        public override char GetChar(int ordinal)
        {
            return GetString(ordinal)[0];
        }

        public override long GetChars(int ordinal, long dataOffset, char[] buffer, int bufferOffset, int length)
        {
            return 0;
        }

        public override string GetDataTypeName(int ordinal)
        {
            return "TEXT";
        }

        public override Type GetProviderSpecificFieldType(int ordinal)
        {
            return typeof(object);
        }

        public override object GetProviderSpecificValue(int ordinal)
        {
            return GetValue(ordinal);
        }

        public override int GetProviderSpecificValues(object[] values)
        {
            return GetValues(values);
        }

        public override int GetValues(object[] values)
        {
            int count = Math.Min(values.Length, FieldCount);
            for (int i = 0; i < count; i++) values[i] = GetValue(i);
            return count;
        }

        public override System.Collections.IEnumerator GetEnumerator()
        {
            throw new NotImplementedException();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) Close();
            base.Dispose(disposing);
        }
    }

    /// <summary>
    /// Minimal DbDataAdapter for filling DataTables.
    /// </summary>
    public sealed class HermesSQLiteDataAdapter : DbDataAdapter
    {
        private HermesSQLiteCommand _selectCommand;

        public new HermesSQLiteCommand SelectCommand
        {
            get { return _selectCommand; }
            set
            {
                _selectCommand = value;
                base.SelectCommand = value;
            }
        }

        protected override int Fill(DataTable dataTable, IDbCommand command, CommandBehavior behavior)
        {
            HermesSQLiteCommand cmd = (HermesSQLiteCommand)command;
            using (HermesSQLiteDataReader reader = (HermesSQLiteDataReader)cmd.ExecuteReader())
            {
                for (int i = 0; i < reader.FieldCount; i++)
                    dataTable.Columns.Add(reader.GetName(i), typeof(string));

                while (reader.Read())
                {
                    DataRow row = dataTable.NewRow();
                    for (int i = 0; i < reader.FieldCount; i++)
                        row[i] = reader.GetValue(i);
                    dataTable.Rows.Add(row);
                }
            }
            return dataTable.Rows.Count;
        }
    }

    internal static class NativeMethods
    {
        private const string DLL = "winsqlite3";

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_open(string filename, out IntPtr ppDb);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_close(IntPtr db);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern IntPtr sqlite3_errmsg(IntPtr db);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_prepare_v2(IntPtr db, string sql, out IntPtr ppStmt);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_step(IntPtr stmt);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_finalize(IntPtr stmt);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_changes(IntPtr db);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_column_count(IntPtr stmt);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_column_type(IntPtr stmt, int iCol);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern IntPtr sqlite3_column_name(IntPtr stmt, int N);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern IntPtr sqlite3_column_text(IntPtr stmt, int iCol);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern long sqlite3_column_int64(IntPtr stmt, int iCol);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern double sqlite3_column_double(IntPtr stmt, int iCol);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_bind_parameter_index(IntPtr stmt, string name);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_bind_null(IntPtr stmt, int index);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_bind_int(IntPtr stmt, int index, int value);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_bind_int64(IntPtr stmt, int index, long value);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_bind_double(IntPtr stmt, int index, double value);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_bind_text(IntPtr stmt, int index, string value);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_bind_blob(IntPtr stmt, int index, byte[] value, int length);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern long sqlite3_last_insert_rowid(IntPtr db);

        [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
        internal static extern int sqlite3_total_changes(IntPtr db);
    }
}