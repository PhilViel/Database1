EXECUTE sp_addextendedproperty @name = N'COPIE_SECURITE', @value = N'Oui';


GO
EXECUTE sp_addextendedproperty @name = N'DATE_EXPIRATION', @value = N'S/O';


GO
EXECUTE sp_addextendedproperty @name = N'ENVIRONNEMENT_DEV', @value = N'Production';


GO
EXECUTE sp_addextendedproperty @name = N'FREQUENCE_COPIE_SECURITE', @value = N'';


GO
EXECUTE sp_addextendedproperty @name = N'NOM_CREATEUR', @value = N'Pierre-Luc Simard';


GO
EXECUTE sp_addextendedproperty @name = N'NOM_RESPONSABLE', @value = N'Pierre-Luc Simard';


GO
EXECUTE sp_addextendedproperty @name = N'SOURCE', @value = N'';


GO
EXECUTE sp_addextendedproperty @name = N'UTILISATION', @value = N'Environnement de production';


GO
EXECUTE sp_addextendedproperty @name = N'VERSION_APPLI_IQEE', @value = N'2.0.0';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'4 - type SGRC pas editable', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VNotes', @level2type = N'COLUMN', @level2name = N'iId_TypeObjet';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique du bénéficiaire. Il correspond en fait à un HumanID qui est le ID unique de l''humain.  Il fait le lien avec la table Mo_Human qui contient les données génériques au humain.', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'BeneficiaryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du tuteur.', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'iTutorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le tuteur (iTutorID) est un souscripteur (Un_Subscriber) ou seulement un tuteur (Un_Tutor).', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'bTutorIsSubscriber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS ou NE du principal responsable.', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'vcPCGSINorEN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du principal responsable.', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'vcPCGFirstName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du principal responsable.', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'vcPCGLastName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de principal responsable (1 = Personne avec un NAS, 2 = Compagnie avec un NE)', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'tiPCGType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le principale responsable est un souscripteur ou non.', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'bPCGIsSubscriber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''entreprise du principal responsable au Québec', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'ResponsableNEQ';

