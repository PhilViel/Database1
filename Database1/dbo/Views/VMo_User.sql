CREATE VIEW VMo_User
	AS
	  SELECT
	    UserID,
	    LoginNameID,
	    PassWordID,
	    PasswordDate,
	    CodeID,
	    CASE 
	       WHEN TerminatedDate IS NULL OR TerminatedDate > GetDate() THEN 'A'
	       ELSE 'I'
	    END AS USerStatusID
	  FROM Mo_User

GO
GRANT SELECT
    ON OBJECT::[dbo].[VMo_User] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue sur la table Mo_User', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VMo_User';

